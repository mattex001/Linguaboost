// tts-speak: neural pronunciation audio via Google Cloud Text-to-Speech.
// Two actions:
//   { action: "speak",  text, languageCode, voiceName? } -> { audioContent } (base64 MP3)
//   { action: "voices", languageCode }                   -> { voices: [{name, languageCode}] }
//
// Requires the GOOGLE_TTS_API_KEY secret (GCP API key with the
// Cloud Text-to-Speech API enabled):
//   supabase secrets set GOOGLE_TTS_API_KEY=...
//
// The client caches returned audio on-device per (voice, language, text),
// so each unique phrase is synthesized once per device, not per play.

import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/translation.ts";

const GOOGLE_TTS_BASE = "https://texttospeech.googleapis.com/v1";

// Our catalog uses ISO/locale codes that mostly match Google's, with two
// exceptions. Yoruba/Igbo have no Google voices — "voices" returns [] and
// the app falls back to device TTS.
function toGoogleLanguageCode(code: string): string {
  if (code === "ar-SA") return "ar-XA";
  if (code === "zh-CN") return "cmn-CN";
  return code;
}

// Prefer the most natural tiers first when listing voices.
const TIER_ORDER = ["Chirp3", "Chirp", "Neural2", "Wavenet", "Standard"];
function tierRank(name: string): number {
  const index = TIER_ORDER.findIndex((tier) => name.includes(tier));
  return index === -1 ? TIER_ORDER.length : index;
}

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

  const apiKey = Deno.env.get("GOOGLE_TTS_API_KEY");
  if (!apiKey) {
    return jsonResponse({ error: "TTS is not configured on the server." }, 503);
  }

  let body: {
    action?: unknown;
    text?: unknown;
    languageCode?: unknown;
    voiceName?: unknown;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const action = typeof body.action === "string" ? body.action : "speak";
  const languageCode = toGoogleLanguageCode(
    typeof body.languageCode === "string" ? body.languageCode : "",
  );
  if (!languageCode) {
    return jsonResponse({ error: "languageCode is required" }, 400);
  }

  try {
    if (action === "voices") {
      const res = await fetch(
        `${GOOGLE_TTS_BASE}/voices?languageCode=${languageCode}&key=${apiKey}`,
      );
      if (!res.ok) throw new Error(`voices list failed: ${res.status}`);
      const data = await res.json() as {
        voices?: { name: string; languageCodes: string[] }[];
      };
      const voices = (data.voices ?? [])
        .sort((a, b) => tierRank(a.name) - tierRank(b.name))
        .slice(0, 5)
        .map((v) => ({ name: v.name, languageCode: v.languageCodes[0] }));
      return jsonResponse({ voices });
    }

    const text = typeof body.text === "string" ? body.text.trim() : "";
    if (text.length < 1 || text.length > 500) {
      return jsonResponse(
        { error: "text must be a string of 1-500 characters" },
        400,
      );
    }
    const voiceName = typeof body.voiceName === "string" && body.voiceName
      ? body.voiceName
      : undefined;

    const res = await fetch(
      `${GOOGLE_TTS_BASE}/text:synthesize?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          input: { text },
          voice: { languageCode, ...(voiceName ? { name: voiceName } : {}) },
          audioConfig: { audioEncoding: "MP3", speakingRate: 0.9 },
        }),
      },
    );
    if (!res.ok) {
      const detail = await res.text();
      console.error("tts synthesize failed:", res.status, detail);
      throw new Error(`synthesize failed: ${res.status}`);
    }
    const data = await res.json() as { audioContent?: string };
    if (!data.audioContent) throw new Error("no audioContent in response");
    return jsonResponse({ audioContent: data.audioContent });
  } catch (err) {
    console.error("tts-speak failed:", err);
    return jsonResponse({ error: "Speech generation failed." }, 502);
  }
});
