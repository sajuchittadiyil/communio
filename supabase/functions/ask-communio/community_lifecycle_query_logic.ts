export type CommunityLifecycleKind = "OPENED" | "CLOSED";

export function lifecycleAnswer(
  kind: CommunityLifecycleKind,
  year: number,
  names: string[],
): string {
  const action = kind === "OPENED" ? "opening" : "closing";
  if (!names.length) {
    return `No communities are recorded as ${action} in ${year}.`;
  }
  return `${names.length} communit${
    names.length === 1 ? "y is" : "ies are"
  } recorded as ${action} in ${year}:\n• ${names.join("\n• ")}`;
}

export function lifecycleEvidenceLabel(kind: CommunityLifecycleKind): string {
  return kind === "OPENED" ? "Community opening" : "Community closure";
}
