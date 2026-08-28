export type Wave3Row = Record<string, unknown>;

const value = (row: Wave3Row, ...keys: string[]): string => {
  for (const key of keys) {
    if (row[key] != null && String(row[key]).trim()) {
      return String(row[key]).trim();
    }
  }
  return "";
};

export function normalizeQualificationQuery(input: string): string[] {
  const normalized = input.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
  if (/\bb\s*th\b|\bbachelor(?:s)?\s+(?:of\s+)?theology\b/.test(normalized)) {
    return ["bth", "bachelor theology", "bachelor of theology"];
  }
  if (/formation.*diploma|diploma.*formation/.test(normalized)) {
    return ["formation diploma", "diploma formation", "diploma in formation"];
  }
  if (/theology.*master|master.*theology|\bm\s*th\b/.test(normalized)) {
    return ["mth", "master theology", "master of theology", "theology master"];
  }
  return [normalized.replaceAll(" ", ""), normalized].filter(Boolean);
}

export function qualificationMatches(row: Wave3Row, query: string): boolean {
  const haystack = [
    value(
      row,
      "qualification",
      "degree",
      "qualification_name",
      "qualification_code",
    ),
    value(
      row,
      "specialization",
      "field_of_study",
      "subject",
      "primary_subject",
    ),
    value(row, "institution", "institution_name"),
  ].join(" ").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
  const compact = haystack.replaceAll(" ", "");
  return normalizeQualificationQuery(query).some((alias) =>
    alias.includes(" ") ? haystack.includes(alias) : compact.includes(alias)
  );
}

export function canonicalRole(input: string): string {
  const normalized = input.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(
    /^_+|_+$/g,
    "",
  );
  const aliases: Record<string, string> = {
    bursar: "provincial_bursar",
    treasurer: "provincial_bursar",
    provincial_treasurer: "provincial_bursar",
    formation_director: "formation_director",
    novice_master: "novice_master",
    school_principal: "principal",
  };
  return aliases[normalized] ?? normalized;
}

export function roleOf(row: Wave3Row): string {
  return canonicalRole(
    value(
      row,
      "role_code",
      "responsibility_code",
      "office_type_code",
      "office_code",
      "office_type",
      "office_name",
      "role_name",
      "responsibility_name",
    ),
  );
}

export function eligibilityStatus(
  row: Wave3Row,
): "ELIGIBLE" | "CONDITIONAL" | "NOT ELIGIBLE" | "NOT EVALUATED" {
  const raw = value(row, "eligibility_status", "status", "compliance_status")
    .toUpperCase().replaceAll("_", " ");
  if (raw === "ELIGIBLE" || raw === "COMPLIANT") return "ELIGIBLE";
  if (raw === "CONDITIONAL") return "CONDITIONAL";
  if (
    raw === "NOT ELIGIBLE" || raw === "NOT COMPLIANT" || raw === "INELIGIBLE"
  ) return "NOT ELIGIBLE";
  return "NOT EVALUATED";
}

export function currentAppointmentCompliance(
  appointments: Wave3Row[],
  evaluations: Wave3Row[],
): Wave3Row[] {
  return appointments.map((appointment) => {
    const memberId = value(appointment, "member_id");
    const role = roleOf(appointment);
    const evaluation = evaluations.find((candidate) =>
      value(candidate, "member_id") === memberId && roleOf(candidate) === role
    );
    const status = evaluation ? eligibilityStatus(evaluation) : "NOT EVALUATED";
    return {
      ...appointment,
      compliance_status: status === "ELIGIBLE"
        ? "COMPLIANT"
        : status === "NOT ELIGIBLE"
        ? "NOT COMPLIANT"
        : status,
      compliance_reason: evaluation
        ? value(
          evaluation,
          "eligibility_reason",
          "reason",
          "reason_text",
          "explanation",
        ) || undefined
        : undefined,
      rule_code: evaluation
        ? value(
          evaluation,
          "rule_code",
          "eligibility_rule_code",
          "rule_version",
        ) || undefined
        : undefined,
    };
  });
}

export function isRestrictedProfileQuestion(question: string): boolean {
  return /\b(?:last will(?: and testament)?|will and testament|testament|will of|vault|digital safe|confidential personnel|personnel file|private documents?)\b|(?:'s|s')\s+will\b/i
    .test(
      question,
    );
}
