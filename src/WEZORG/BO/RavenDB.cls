/// Handle queries towards RavenDB
Class WEZORG.BO.RavenDB Extends Ens.BusinessOperation
{

Parameter ADAPTER = "EnsLib.HTTP.OutboundAdapter";

Property Adapter As EnsLib.HTTP.OutboundAdapter;

/// POST /databases/{db}/queries"
Method Query(requestMessage As WEZORG.Msg.RavenDB.QueryRequest, Output responseMessage As WEZORG.Msg.RavenDB.QueryResponse) As %Status
{
	set responseMessage = ##class(WEZORG.Msg.RavenDB.QueryResponse).%New()
	return ..zzHandleRequest(requestMessage, "Query", "POST", responseMessage)
}

/// Common request handler
Method zzHandleRequest(requestMessage As Ens.Request, name As %String, method As %String, responseMessage As WEZORG.Msg.RavenDB.GenericResponse) As %Status
{
	set sc = $$$OK, pHttpRequestIn = ##class(%Net.HttpRequest).%New()
	$$$QuitOnError(requestMessage.LoadHttpRequestObject(pHttpRequestIn))
	set sc = ..Adapter.SendFormDataArray(.pHttpResponse, method, pHttpRequestIn, , , ..Adapter.URL _ requestMessage.%URL)

	if $$$ISERR(sc) && ($SYSTEM.Status.GetErrorCodes(sc) '= $$$EnsErrHTTPStatus) {
		return sc
	}

	if $ISOBJECT(pHttpResponse) {
		$$$TRACE(name _" returned " _ pHttpResponse.StatusCode)
		$$$QuitOnError(responseMessage.LoadFromResponse(pHttpResponse, name))
	}

	return sc
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="WEZORG.Msg.RavenDB.QueryRequest">
		<Method>Query</Method>
	</MapItem>
</MapItems>
}

}
