import type { AskCommunioContext } from "./intent_interpreter.ts";

export type SemanticEntity = { type: string; id: string; name: string };
export type SemanticContext = {
  focus?: SemanticEntity;
  lastAnswer?: SemanticEntity;
  entitySet?: { type: string; entities: SemanticEntity[] };
};

export function applySemanticContext(
  base: AskCommunioContext,
  semantic: SemanticContext,
): AskCommunioContext {
  const context = { ...base };
  if (semantic.focus) {
    context.focus_entity_type = semantic.focus.type;
    context.focus_entity_id = semantic.focus.id;
    context.focus_entity_name = semantic.focus.name;
    context.primary_entity_type = semantic.focus.type;
    context.primary_entity_id = semantic.focus.id;
    context.primary_entity_name = semantic.focus.name;
  }
  if (semantic.lastAnswer) {
    context.last_answer_entity_type = semantic.lastAnswer.type;
    context.last_answer_entity_id = semantic.lastAnswer.id;
    context.last_answer_entity_name = semantic.lastAnswer.name;
  }
  if (semantic.entitySet) {
    context.entity_set_type = semantic.entitySet.type;
    context.entity_set_size = semantic.entitySet.entities.length;
    if (semantic.entitySet.entities.length > 1 && !semantic.focus) {
      context.ambiguous_entity_type = semantic.entitySet.type;
    }
  }
  return context;
}
