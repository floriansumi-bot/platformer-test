/**
 * Fridge Chef — AI ingredient detection backend (Cloudflare Worker).
 *
 * Holds ONE API key so the public web app never has to. The frontend POSTs a
 * base64 photo to /detect and gets back a list of ingredients.
 *
 * Provider is selectable so you can use whichever tokens you already have:
 *   PROVIDER = "openai"     (default) — uses OPENAI_API_KEY  + OPENAI_MODEL
 *   PROVIDER = "anthropic"            — uses ANTHROPIC_API_KEY + ANTHROPIC_MODEL
 *
 * Deploy:
 *   cd worker
 *   npx wrangler secret put OPENAI_API_KEY      # paste your OpenAI key
 *   npx wrangler deploy
 */

export interface Env {
  PROVIDER?: string;
  OPENAI_API_KEY?: string;
  OPENAI_MODEL?: string;
  ANTHROPIC_API_KEY?: string;
  ANTHROPIC_MODEL?: string;
  ALLOWED_ORIGIN?: string;
}

const SYSTEM_PROMPT =
  "You identify food ingredients in a photo of a fridge, freezer or pantry. " +
  "List the individual, distinct food ingredients you can actually see " +
  "(e.g. egg, milk, tomato, chicken, cheese, carrot, butter). Use simple, " +
  "singular, lowercase names. Ignore non-food items, brand names, and " +
  "containers. Do not guess items that are not visible.";

const INGREDIENTS_SCHEMA = {
  type: "object",
  properties: {
    ingredients: {
      type: "array",
      items: { type: "string" },
      description: "Lowercase singular food ingredient names visible in the photo.",
    },
  },
  required: ["ingredients"],
  additionalProperties: false,
} as const;

function cors(env: Env): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": env.ALLOWED_ORIGIN || "*",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
  };
}

function json(body: unknown, status: number, env: Env): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...cors(env) },
  });
}

function provider(env: Env): "openai" | "anthropic" {
  return (env.PROVIDER || "openai").toLowerCase() === "anthropic" ? "anthropic" : "openai";
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors(env) });
    }

    const url = new URL(request.url);

    if (request.method === "GET") {
      const p = provider(env);
      const keyPresent =
        p === "openai" ? Boolean(env.OPENAI_API_KEY) : Boolean(env.ANTHROPIC_API_KEY);
      return json(
        { ok: true, service: "fridge-chef-detect", provider: p, configured: keyPresent },
        200,
        env,
      );
    }

    if (request.method !== "POST" || url.pathname !== "/detect") {
      return json({ error: "Not found. POST an image to /detect." }, 404, env);
    }

    let payload: { image?: string; media_type?: string };
    try {
      payload = await request.json();
    } catch {
      return json({ error: "Invalid JSON body." }, 400, env);
    }

    const image = payload.image?.trim();
    const mediaType = payload.media_type || "image/jpeg";
    if (!image) return json({ error: "Missing 'image' (base64) in body." }, 400, env);

    try {
      const result =
        provider(env) === "anthropic"
          ? await detectAnthropic(image, mediaType, env)
          : await detectOpenAI(image, mediaType, env);
      return json(result, 200, env);
    } catch (err) {
      return json({ error: (err as Error).message || "Detection failed." }, 502, env);
    }
  },
};

// ---- OpenAI (default) -------------------------------------------------------

async function detectOpenAI(
  base64: string,
  mediaType: string,
  env: Env,
): Promise<{ ingredients: string[]; model: string }> {
  if (!env.OPENAI_API_KEY) throw new Error("Server has no OPENAI_API_KEY configured.");
  const model = env.OPENAI_MODEL || "gpt-4o-mini";

  const res = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model,
      max_tokens: 600,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        {
          role: "user",
          content: [
            { type: "text", text: "What food ingredients can you see? Return JSON." },
            {
              type: "image_url",
              image_url: { url: `data:${mediaType};base64,${base64}`, detail: "low" },
            },
          ],
        },
      ],
      response_format: {
        type: "json_schema",
        json_schema: { name: "ingredients", strict: true, schema: INGREDIENTS_SCHEMA },
      },
    }),
  });

  if (!res.ok) {
    throw new Error(`OpenAI error ${res.status}: ${await safeBody(res)}`);
  }

  const data = (await res.json()) as {
    choices?: { message?: { content?: string } }[];
  };
  const content = data.choices?.[0]?.message?.content ?? "{}";
  return { ingredients: parseIngredients(content), model };
}

// ---- Anthropic (optional) ---------------------------------------------------

async function detectAnthropic(
  base64: string,
  mediaType: string,
  env: Env,
): Promise<{ ingredients: string[]; model: string }> {
  if (!env.ANTHROPIC_API_KEY) throw new Error("Server has no ANTHROPIC_API_KEY configured.");
  const model = env.ANTHROPIC_MODEL || "claude-opus-4-8";

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model,
      max_tokens: 600,
      system: SYSTEM_PROMPT,
      thinking: { type: "disabled" },
      output_config: {
        effort: "low",
        format: { type: "json_schema", schema: INGREDIENTS_SCHEMA },
      },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "image",
              source: { type: "base64", media_type: mediaType, data: base64 },
            },
            { type: "text", text: "What food ingredients can you see? Return JSON." },
          ],
        },
      ],
    }),
  });

  if (!res.ok) {
    throw new Error(`Anthropic error ${res.status}: ${await safeBody(res)}`);
  }

  const data = (await res.json()) as { content?: { type: string; text?: string }[] };
  const text = data.content?.find((b) => b.type === "text")?.text ?? "{}";
  return { ingredients: parseIngredients(text), model };
}

// ---- helpers ----------------------------------------------------------------

function parseIngredients(raw: string): string[] {
  try {
    const obj = JSON.parse(raw);
    const list = Array.isArray(obj?.ingredients) ? obj.ingredients : [];
    const cleaned = list
      .map((x: unknown) => String(x).trim().toLowerCase())
      .filter((x: string) => x.length > 0 && x.length < 40);
    return Array.from(new Set(cleaned));
  } catch {
    return [];
  }
}

async function safeBody(res: Response): Promise<string> {
  try {
    return (await res.text()).slice(0, 300);
  } catch {
    return "<no body>";
  }
}
