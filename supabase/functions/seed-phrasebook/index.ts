// seed-phrasebook: cold-start onboarding (PRD §9.4), also re-run whenever a
// user switches to a language they've never practiced before. Translates 8
// fixed relocation-starter phrases and inserts them as seeded,
// immediately-due phrase rows. Idempotent per target_lang: no-op if the user
// already has phrases in that specific language.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { SUPPORTED_LANGS } from "../_shared/taxonomy.ts";
import {
  corsHeaders,
  getAnthropicClient,
  jsonResponse,
  translateOne,
} from "../_shared/translation.ts";

const SEED_PHRASES = [
  "Hello, nice to meet you",
  "How much does this cost?",
  "Where is the nearest pharmacy?",
  "I'd like to open a bank account",
  "Can you speak more slowly, please?",
  "I'm looking for an apartment",
  "What time does the bus leave?",
  "I need help with this form",
];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonResponse({ error: "Missing authorization" }, 401);

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: authError } = await userClient.auth.getUser();
  if (authError || !user) return jsonResponse({ error: "Unauthorized" }, 401);

  let body: { targetLang?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }
  const targetLang = typeof body.targetLang === "string" ? body.targetLang : "";
  if (!(targetLang in SUPPORTED_LANGS)) {
    return jsonResponse(
      { error: `targetLang must be one of: ${Object.keys(SUPPORTED_LANGS).join(", ")}` },
      400,
    );
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Idempotency guard: skip if the user already has phrases in this language.
  const { count, error: countError } = await admin
    .from("phrases")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("target_lang", targetLang);
  if (countError) {
    console.error("seed-phrasebook count failed:", countError);
    return jsonResponse({ error: "Could not check existing phrases" }, 500);
  }
  if ((count ?? 0) > 0) {
    return jsonResponse({ count: 0, skipped: true });
  }

  try {
    const anthropic = getAnthropicClient();
    const translations = await Promise.all(
      SEED_PHRASES.map((phrase) => translateOne(anthropic, phrase, "en", targetLang)),
    );

    const rows = translations.map((t, i) => ({
      user_id: user.id,
      source_text: SEED_PHRASES[i],
      translated_text: t.translatedText,
      source_lang: "en",
      target_lang: targetLang,
      register_note: t.registerNote,
      category: t.category,
      confidence: t.confidence,
      confidence_note: t.confidenceNote,
      seeded: true,
      vocab_breakdown: t.vocabBreakdown,
      grammar_note: t.grammarNote,
      pronunciation: t.pronunciation,
    }));

    const { error: insertError } = await admin.from("phrases").insert(rows);
    if (insertError) throw insertError;

    return jsonResponse({ count: rows.length, skipped: false });
  } catch (err) {
    console.error("seed-phrasebook failed:", err);
    return jsonResponse({ error: "Seeding failed" }, 502);
  }
});
