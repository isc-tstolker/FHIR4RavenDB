/// RavenDB Query Request 
Class WEZORG.Msg.RavenDB.GetDocumentRequest Extends Ens.Request [ ProcedureBlock ]
{

Parameter METHOD = "GET";

Parameter URL = "/databases/{db}/docs";

Property %Consume As %String(MAXLEN = "") [ InitialExpression = "application/json" ];

Property %URL As %String(MAXLEN = "") [ InitialExpression = {..#URL} ];

/// Database
Property pathdb As %String(MAXLEN = "");

/// Document id
Property queryid As %String(MAXLEN = "");

/// Load %Net.HttpRequest with this property object.
Method LoadHttpRequestObject(ByRef httpRequest As %Net.HttpRequest) As %Status
{
	set sc = $$$OK
	do httpRequest.SetHeader("accept", ..%Consume)
	Set ..%URL = $Replace(..#URL,"{db}", ..pathdb)
	do httpRequest.SetParam("id", ..queryid)
	
	return sc
}

Storage Default
{
<Data name="QueryRequestDefaultData">
<Subscript>"QueryRequest"</Subscript>
<Value name="1">
<Value>%Consume</Value>
</Value>
<Value name="2">
<Value>%ContentType</Value>
</Value>
<Value name="3">
<Value>%URL</Value>
</Value>
<Value name="4">
<Value>pathdb</Value>
</Value>
<Value name="5">
<Value>Query</Value>
</Value>
<Value name="6">
<Value>queryid</Value>
</Value>
</Data>
<DefaultData>QueryRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
