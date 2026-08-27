import { canonicalMemberCategory, isCurrentEffectiveRow, memberScopedRows } from "./query_guards.ts";

Deno.test("member appointment history cannot include another member's rows", () => {
  const rows = memberScopedRows([
    { id: "wanted-office", member_id: "joseph" },
    { id: "unrelated-office", member_id: "francis" },
  ], "joseph");
  if (rows.length !== 1 || rows[0].member_id !== "joseph") {
    throw new Error("member-scoped appointment guard leaked another member");
  }
});

Deno.test("current assignment guard excludes future and expired rows", () => {
  const today = "2026-08-27";
  if (!isCurrentEffectiveRow({ from_date: "2020-01-01", to_date: null }, today)) throw new Error("open current row rejected");
  if (isCurrentEffectiveRow({ from_date: "2020-01-01", to_date: "2025-12-31" }, today)) throw new Error("expired row accepted");
  if (isCurrentEffectiveRow({ from_date: "2027-01-01", to_date: null }, today)) throw new Error("future row accepted");
});

Deno.test("member category uses canonical title codes rather than display names", () => {
  if (canonicalMemberCategory("PRIEST") !== "priest") throw new Error("priest code not normalized");
  if (canonicalMemberCategory("Bro.") !== "brother") throw new Error("brother code not normalized");
  if (canonicalMemberCategory("Fr Joseph") !== undefined) throw new Error("display-name-like value was classified");
});
