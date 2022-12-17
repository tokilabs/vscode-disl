grammar DISL

/*
 * UTIL
 */
terminal _: /\s?/;
terminal __: /\s+/;
hidden terminal WS: /[\s\r\n]+/;
hidden terminal EmptyLine: __* EOL;

terminal ID: /[_a-zA-Z][\w_]*/;
terminal EOL: SL_COMMENT? /[\r\n]+/;
terminal TYPE: ID ('<' (','? ID ('[]')? )* '>')?;

terminal ML_COMMENT: /\/\*[\s\S]*?\*\//;
terminal SL_COMMENT: /(\/\/|#)[^\n\r]*/;
terminal COMMENT: ML_COMMENT | SL_COMMENT;

terminal fragment ESCAPED_CHAR: '\\' ('n'|'t'|'r'|'\\');

terminal STRING: '"' ( ESCAPED_CHAR | !('\\'|'"') )* '"';

terminal REST: /[^\n\r]+/;

terminal UNTIL_THEN: /.*(?=then)/;
terminal BLOCK:
  (/[^\r\n]+(?=[\r\n])/ | /[\s]*[\r\n]+([\s\S]*)(?=[\r\n\s]+end)/);

terminal PATH: '"' -> '"';

entry Model:
  (
    aliases+=Alias
  | descriptions+=Desc
  | comments+=COMMENT
  | contexts+=Context)*;

Context:
  'context' __ name=ID EOL
    (
      imports+=Import
    | includes+=Include
    | aliases+=Alias
    | comments+=COMMENT
    | commandDefaults+=CommandDefaults
    | eventDefaults+=EventDefaults
    | aggregates+=Aggregate
    | exceptions=Exception
    | identities=Identity
    | valueObjects=ValueObject
    | services=Service
    )*;

Identity:
	'identity' name=ID type=TYPE EOL;

Alias:
	'alias' __ name=ID (__ 'to')? __ varName=ID __? ':'? __? type=TYPE EOL;

AliasRef:
  ':' name=ID (optional?='?')?;

Aggregate:
  "aggregate" name=ID
    (
      comments+=COMMENT
    | defaults+=CommandDefaults
    | defaults+=EventDefaults
    | defaults+=ExceptionDefaults
    | exceptions+=Exception
    | identities+=Identity
    | roots+=AggregateRoot
    | entities+=Entity
    | valueObjects+=ValueObject
    )*;

AggregateRoot:
  'root' name=ID
    (
      aliases+=Alias
		| comments+=COMMENT
    | commands+=Command
    | events+=Event
		| exceptions+=Exception
    | imports+=Import
    )*;

Param:
  name=ID optional?="?" ":" type=TYPE;

ParamOrAlias:
  Param | AliasRef;

ParamList:
  params+=ParamOrAlias (","? params+=ParamOrAlias)*;

Property:
  '@' name=ID (optional?='?')? ':' type=TYPE ("=" initializer=(STRING|REST))? EOL;

Command:
  ('command' name=ID | name=ID "?") (params+=ParamList)*
    (
      comments+=COMMENT
    | descs+=Desc
    | imports+=Import
    | properties+=Property
    | rules+=RulesRule
    | events+=Event
    )*;

RulesRule:
  "rules:" (rules+=WhenRule)+;

WhenRule:
  'when' when=UNTIL_THEN 'then' then=BLOCK;

Event:
  ('event' name=ID | name=ID "!") params=ParamList
    (
      comments+=COMMENT
    | imports+=Import
    | properties+=Property
    )*;

Entity:
  'entity' name=ID EOL
  (
      comments+=COMMENT
    | descs+=Desc
    | imports+=Import
    | properties+=Property
  )*;

Service:
  'service' name=ID EOL
    (
      comments+=COMMENT
    | commands+=Command
    | descs+=Desc
    | imports+=Import
    | properties+=Property
    )*;

Exception:
  '!' name=ID params+=ParamList;

ValueObject:
  'ValueObject' name=ID EOL
    (
      comments+=COMMENT
    | descs+=Desc
    | imports+=Import
    | properties+=Property
    )*;

Desc:
  "desc" desc=REST;

terminal IncludeKeywords: 'include' | 'read_also';

Include:
  IncludeKeywords path=PATH EOL;

Import:
  (
    'import' "*" "as" name=ID "from" from=PATH ";"?
    |
    'import' "{"
      exports=ExportedList
    "}" "from" from=PATH ";"?
  );

Exported:
  name=ID ("as" alias=ID)?;

ExportedList:
  items+=Exported ("," items+=Exported)*;

fragment ImplementExtendImport:
      implement=Implement
    | extend=Extend
    | imports+=Import;

CommandDefaults:
	'commands' EOL
    ImplementExtendImport+;

EventDefaults:
	'events' EOL
    (
      ImplementExtendImport
      source=EventSource
    )+;

EventSource:
  ('source' source=[Aggregate:ID])?;

ExceptionDefaults:
	'exceptions' EOL
    ImplementExtendImport+;

/*
 * PARTIALS
 */
fragment ImplExt:
  impl=Implement & ext=Extend;

Implement:
  "implements" implement=TYPE;

Extend:
  'extends' extend=TYPE;

