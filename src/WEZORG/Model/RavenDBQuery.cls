/// Query body
Class WEZORG.Model.RavenDBQuery Extends (%SerialObject, %JSON.Adaptor, %XML.Adaptor) [ Inheritance = left, ProcedureBlock ]
{

/// RavenDB Query
Property Query As %String(MAXLEN = "");

Storage Default
{
<Data name="RavenDBQueryState">
<Value name="1">
<Value>Query</Value>
</Value>
</Data>
<State>RavenDBQueryState</State>
<StreamLocation>^WEZORG.Model.RavenDBQueryS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
