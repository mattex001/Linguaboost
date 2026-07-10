// translate-phrase: English sentence -> translation + AI explanation (FR-1.x).
// The client writes the phrase row itself after a successful response (FR-2.1).

import { createClient } from "jsr:@supabase/supabase-js@2";
import { SUPPORTED_LANGS } from "../_shared/taxonomy.ts";
import {
  corsHeaders,
  getAnthropicClient,
  jsonResponse,
  translateOne,
} from "../_shared/translation.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonResponse({ error: "Missing authorization" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) return jsonResponse({ error: "Unauthorized" }, 401);

  let body: { text?: unknown; sourceLang?: unknown; targetLang?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const text = typeof body.text === "string" ? body.text.trim() : "";
  const sourceLang =
    typeof body.sourceLang === "string" && body.sourceLang.length > 0
      ? body.sourceLang
      : "en";
  const targetLang = typeof body.targetLang === "string" ? body.targetLang : "";

  if (text.length < 1 || text.length > 500) {
    return jsonResponse(
      { error: "text must be a string of 1-500 characters" },
      400,
    );
  }
  if (!(sourceLang in SUPPORTED_LANGS)) {
    return jsonResponse(
      { error: `sourceLang must be one of: ${Object.keys(SUPPORTED_LANGS).join(", ")}` },
      400,
    );
  }
  if (!(targetLang in SUPPORTED_LANGS)) {
    return jsonResponse(
      { error: `targetLang must be one of: ${Object.keys(SUPPORTED_LANGS).join(", ")}` },
      400,
    );
  }
  if (sourceLang === targetLang) {
    return jsonResponse(
      { error: "sourceLang and targetLang must be different" },
      400,
    );
  }

  try {
    const result = await translateOne(getAnthropicClient(), text, sourceLang, targetLang);
    return jsonResponse(result);
  } catch (err) {
    console.error("translate-phrase failed:", err);
    return jsonResponse({ error: "Translation failed. Please try again." }, 502);
  }
});
