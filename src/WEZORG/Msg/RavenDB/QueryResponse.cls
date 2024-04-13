/// Query Response
Class WEZORG.Msg.RavenDB.QueryResponse Extends (WEZORG.Msg.RavenDB.GenericResponse, %XML.Adaptor) [ ProcedureBlock ]
{

/// Calculate Result
Method Result() As %DynamicObject
{
	return {}.%FromJSON(..body)
}

/// post "/databases/{db}/queries";
Method LoadFromResponse(httpResponse As %Net.HttpResponse, caller As %String = "") As %Status
{
	set sc = $$$OK
	do ##super(httpResponse, caller)

	return sc
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
