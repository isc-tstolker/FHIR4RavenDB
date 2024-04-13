/// RavenDB Query Request 
Class WEZORG.Msg.RavenDB.QueryRequest Extends Ens.Request [ ProcedureBlock ]
{

Parameter METHOD = "POST";

Parameter URL = "/databases/{db}/queries";

Property %Consume As %String(MAXLEN = "") [ InitialExpression = "application/json" ];

Property %ContentType As %String(MAXLEN = "") [ InitialExpression = "application/json" ];

Property %URL As %String(MAXLEN = "") [ InitialExpression = {..#URL} ];

Property pathdb As %String(MAXLEN = "") [ InitialExpression = "wezorg" ];

/// Use this property for body content with content-type = application/json.
Property Query As WEZORG.Model.RavenDBQuery;

/// Load %Net.HttpRequest with this property object.
Method LoadHttpRequestObject(ByRef httpRequest As %Net.HttpRequest) As %Status
{
	set httpRequest.ContentType = ..%ContentType
	do httpRequest.SetHeader("accept", ..%Consume)
	Set ..%URL = $Replace(..#URL,"{db}", ..pathdb)
	
	return ..Query.%JSONExportToStream(httpRequest.EntityBody)
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
</Data>
<DefaultData>QueryRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
