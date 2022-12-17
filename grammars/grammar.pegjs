{
  const AST = require('./ast');
}

/*
  // USE THIS TO TEST ONLINE
  // try it on https://pegjs.org/online
{
  function Rule(props) { Object.assign(this, props); }

  const AST = {
  	AliasRefRule: Rule,
  	AST: Rule,
  	CommentRule: Rule,
  	ContextRule: Rule,
  	ExceptionRule: Rule,
    AggregateRootRule: Rule,
    AggregateRule: Rule,
    AliasRule: Rule,
    CommandDefaultsRule: Rule,
    CommandRule: Rule,
    EntityRule: Rule,
    EventDefaultsRule: Rule,
    EventRule: Rule,
    IdentityRule: Rule,
    ImportRule: Rule,
    ParamRule: Rule,
    PropertyRule: Rule,
    WhenRule: Rule
  }
}
*/

start = rules:World { return new AST.AST(rules) }

IgnoredRules =
   __
  / EmptyLine
  / EOL

World = rules:(IgnoredRules* r:(
  Alias
  / Desc
  / COMMENT
  / CommandDefaults
  / EventDefaults
  / Exception
  / ExceptionDefaults
  / Identity
  / ValueObjectScope
  / ContextScope) IgnoredRules* {return r})* {return rules}

ContextScope =
  _ name:Context rules:( ContextRules )* { return new AST.ContextRule({ name }, rules) }

    Context "context" = _ "context" __ name:ID EOL? { return name }

    ContextRules = IgnoredRules* r:(
      Alias
      / COMMENT
      / Desc
      / CommandDefaults
      / EventDefaults
      / ExceptionDefaults
      / Exception
      / Identity
      / AggregateScope
      / ValueObjectScope
      / ServiceScope
    ) { return r }

      AggregateScope = _ name:Aggregate rules:( AggregateRules )* {
        return new AST.AggregateRule({ name }, rules)
      }

        Aggregate "aggregate" = _ "aggregate" __ name:ID EOL { return name }

        AggregateRules = IgnoredRules* r:(
          Alias
          / COMMENT
          / Desc
          / CommandDefaults
          / EventDefaults
          / ExceptionDefaults
          / Exception
          / Identity
          / AggregateRootScope
          / EntityScope
          / ValueObjectScope
          ) { return r }

          AggregateRootScope = _ name:AggregateRoot rules:( AggregateRootRules )* {
            return new AST.AggregateRootRule({ name }, rules)
          }

            AggregateRoot "root" = _ "root" __ name:ID EOL { return name }

            AggregateRootRules = IgnoredRules* r:(
              Alias
              / COMMENT
              / Desc
              / Command
              / Event
              / Exception
              / Import
              ) {
                return r
              }

                Command "{commandName}?" = _ name:ID "?" __ params:ParamList _ rules:( CommandRules )* {
                  return new AST.CommandRule({ name, params }, rules.filter(i => typeof i !== 'undefined'))
                }

                    CommandRules = IgnoredRules* r:(
                      COMMENT
                      / Desc
                      / Import
                      / Property
                      / RulesRule
                      / WhenRule
                      / Event
                    ) { return r }

                      RulesRule = _ "rules:" _ EOL { return undefined }
                      WhenRule = _ "when" _ code:$(![\r\n] .)* { return new AST.WhenRule({code})}

                Event "{eventName}!" = _ name:ID "!" __ params:ParamList _ rules:( EventRules )*
                  { return new AST.EventRule({ name, params }, rules) }

                    EventRules = IgnoredRules* r:(
                      COMMENT
                      / Desc
                      / Import
                      / Property
                    ) { return r }

          EntityScope = _ name:Entity rules:( EntityRules )* {
            return new AST.EntityRule({ name }, rules);
          }

            Entity "entity" = _ "entity" __ name:ID EOL { return name }

            EntityRules = IgnoredRules* r:(
              COMMENT
              / Desc
              / Import
              / Property
            ) { return r }

      ServiceScope = _ name:Service _ rules:( ServiceRules )* {
        return { type: "ServiceRule", properties: { name }, rules }
      }

          Service "service" = _ "service" __ name:ID EOL { return name }

          ServiceRules = IgnoredRules* r:(
            COMMENT
            / Command
            / Desc
            / Import
            / Property
          ) { return r }

Exception "!{exceptionName}" = _ "!" _ name:ID __ params:ParamList
  { return new AST.ExceptionRule({ name, params }) }

ValueObjectScope = _ name:ValueObject rules:( ValueObjectRules )* {
  return new AST.ValueObjectRule({ name }, rules);
}

  ValueObject "ValueObject" = _ "valueObject" __ name:ID EOL { return name }

	ValueObjectRules = IgnoredRules* r:(
    COMMENT
    / Desc
    / Import
    / Property
  ) { return r }

Desc "@desc" = _ "@desc" __ desc:$(![\r\n].)* { return new AST.DescRule({ content: desc }); }

Import "import" =
	imp:(
      _ "import" __ "*" __ "as" __ name:ID __ "from" __ from:STRING _ ";"? _  { return { name, from } }
    / _ "import" _ "{" _ EOL? _ exports:ExportedList _ EOL? _ "}"_"from" __ from:STRING _ ";"? EOL { return { exports, from } }) {
    return new AST.ImportRule(imp);
  }

    ExportedList = elist:(","? _ expt:Exported _ EOL? { return expt })*
        Exported = ( name:ID _ "as"? _ alias:ID? { return new AST.PropertyRule({ name, alias }) })

Identity "identity" =
	_ "identity" __ name:ID _ type:ID _ EOL { return new AST.IdentityRule({ name, type }) }

Alias "alias" =
	_ "alias" _ ":" name:ID _ varName:ID _ type:TYPE _ EOL? { return new AST.AliasRule({ name, varName, type }) }
  /
  _ "alias" _ ":" name:ID _ type:TYPE _ EOL? { return new AST.AliasRule({ name, type }) }

CommandDefaults "commands" =
	_ "commands" (EOL / __) def:ImplExt _ EOL? _ imports:(Import)* { return new AST.CommandDefaultsRule(def) }

EventDefaults "events" =
	_ "events" (EOL / __) def:ImplExt? _ EOL? _ source:("source" __ t:ID { return t })? _ EOL? _ imports:(Import)*
  { return new AST.EventDefaultsRule({ impl: def? def.impl : null, ext: def? def.ext : null, source }) }

ExceptionDefaults "exceptions" =
	_ "exceptions" __ EOL? _ def:ImplExt
  { return { exceptionsDefaults: def } }

/*
 * PARTIALS
 */
ImplExt =
	impl:Implement ext:Extend? { return { impl, ext } }
  / ext:Extend impl:Implement? { return { impl, ext } }

    Implement "implements" =
      _ "implements" __ impl:TYPE _ EOL? _ { return impl }

    Extend "extends" =
      _ "extends" __ ext:TYPE _ EOL? _ { return ext }

AliasRef = _ ":" name:ID _ optional:("?")? _ { return new AST.AliasRefRule({ name, optional: !!optional }) }

Param = _ name:ID _ optional:("?")? _ ":" _ type:TYPE _
    { return new AST.ParamRule({ name, type, optional: !!optional }) }

ParamList "parameter list" = (
    ","? p:Param { return p }
  / ","? a:AliasRef { return a; }
)*

Property "prop" = _ name:("@" name:ID { return name }) _ optional:("?"?) _ type:(":" _ type:TYPE { return type })? _ initializer:("=" _ c:$([^\r\n]+) { return c })? EOL
	  { return new AST.PropertyRule({ name, type, optional: !!optional, initializer }) }

COMMENT "comment" =  c:(
    "/*" content:(!"*/" .)* "*/"
  / "#" content:(![\r\n] .)*
  / "//" content:(![\r\n] .)*) {
    return new AST.CommentRule(c);
  }

/*
 * UTIL
 */
_ "optional whitespace" = [ \t]*
__ "mandatory whitespace" = [ \t]+
ID "variable name" = $([a-zA-Z_][a-zA-Z0-9_]*)
STRING "string" = [\'\"] value:$([^\'\"]+) [\'\"] { return value }
EOL "EOL" = _ COMMENT? [\r\n]+
EmptyLine "empty line" = _ EOL
TYPE "type" = $(ID("<" (","? _ p:ID _ {return p})* ">")?("[]")?)
