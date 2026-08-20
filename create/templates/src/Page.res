type element

@val @scope("document") external byId: string => Nullable.t<element> = "getElementById"
@set external shows: (element, string) => unit = "textContent"

byId("root")
->Nullable.toOption
->Option.forEach(root => root->shows("{{name}} is running. Ask the agent for a model."))
