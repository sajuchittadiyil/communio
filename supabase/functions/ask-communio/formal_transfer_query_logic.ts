export type FormalTransferRow = {
  display_name?: string;
  from_community_name?: string;
  to_community_name?: string;
  effective_date?: string;
  reason?: string;
};

export function formalTransferAnswer(
  communityName: string,
  year: number,
  rows: FormalTransferRow[],
): string {
  if (!rows.length) {
    return `I found no recorded formal transfers from ${communityName} in ${year}.`;
  }
  return `${rows.length} formal transfer${
    rows.length === 1 ? " is" : "s are"
  } recorded from ${communityName} in ${year}:\n• ${
    rows.map((row) =>
      `${row.display_name ?? "Religious"} → ${
        row.to_community_name ?? "External destination"
      }${row.effective_date ? ` — ${row.effective_date}` : ""}`
    ).join("\n• ")
  }`;
}

export function memberFormalTransferAnswer(
  memberName: string,
  rows: FormalTransferRow[],
  includeReason = false,
): string {
  if (!rows.length) {
    return `I found no recorded formal transfer for ${memberName}.`;
  }
  const movements = rows.map((row) => {
    const movement = `${row.from_community_name ?? "External origin"} to ${
      row.to_community_name ?? "an external destination"
    }${row.effective_date ? `, effective ${row.effective_date}` : ""}`;
    if (!includeReason) return movement;
    return `${movement}. ${
      row.reason
        ? `Recorded reason: ${row.reason}.`
        : "No transfer reason is recorded."
    }`;
  });
  return `${memberName} has ${
    rows.length === 1 ? "a" : String(rows.length)
  } recorded formal transfer${rows.length === 1 ? "" : "s"}: ${
    movements.join("; ")
  }`;
}
