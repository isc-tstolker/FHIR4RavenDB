/// Generic FHIR Facade pattern
Class WEZORG.BP.FHIR.GenericFacade Extends (Ens.BusinessProcess, HS.HC.Util.Trace.Helper, WEZORG.Util.FHIRServerHelper, WEZORG.Util.StringHelpers, WEZORG.Util.MethodHelper) [ ClassType = persistent ]
{

Parameter SETTINGS = "RavenDB:Connector,Timeout:Basic";

Property RavenDB As Ens.DataType.ConfigName [ InitialExpression = "RavenDB" ];

Property Timeout As %Integer [ InitialExpression = 60 ];

/// Handle request
Method OnRequest(pInteropRequest As HS.FHIRServer.Interop.Request, Output pResponse As HS.FHIRServer.Interop.Response) As %Status
{
	#dim sc As %Status = $$$OK
	
	#dim pRequest as WEZORG.Msg.LocalFHIRInteropRequest = ##class(WEZORG.Msg.LocalFHIRInteropRequest).CreateLocalInteropRequest(pInteropRequest)
	set pResponse = ##class(WEZORG.Msg.LocalFHIRInteropResponse).Create($THIS, ..TraceOperations, pRequest.Request.ResponseFormatCode)
	set ..%response = pResponse 
	
	try
	{
		#dim fhirRequest As HS.FHIRServer.API.Data.Request = pRequest.Request
		$$$TRACE("Received " _ fhirRequest.RequestMethod _" for " _ fhirRequest.RequestPath _ "?" _  fhirRequest.QueryString)

		if (fhirRequest.RequestMethod = "GET") && (fhirRequest.RequestPath = "metadata")
		{
			return $METHOD($THIS, "HandleMetadata", pRequest, pResponse)
		}

		set handlerMethodName = ..GetNormalizedMethodNameAndCheckExists("Handle-" _ pRequest.ResourceType _ "-", $ZCONVERT(fhirRequest.RequestMethod, "L"))

		if handlerMethodName = ""
		{
			return ..WriteErrorAsOutcome(pResponse, 400, "Unsupported " _ fhirRequest.RequestMethod _ " " _ pRequest.ResourceType)
		}

		set sc = $METHOD($THIS, handlerMethodName, pRequest, pResponse)
	}
	catch ex
	{
		#dim ex as %Exception.AbstractException
		set sc = ex.AsStatus()
		
		$$$TRACE("Exception " _ ex.Code)

		// Create operation outcome for parsing error JSON or XML, or validation error
		if ex.Code = $$$HSFHIRErrInvalidJsonContent || (ex.Code = "6301") || (ex.Code = $$$HSFHIRErrValidationFailure)
		{
			return ..WriteStatusResponse(pResponse, sc, 422)
		}
	}

	if $$$ISERR(sc)
	{
		return ..WriteStatusResponse(pResponse, sc)
	}

	return $$$OK
}

/// Returns a minimal OperationOutcome for fatal errors (e.g., status error sending the request on).
ClassMethod WriteErrorAsOutcome(Response As WEZORG.Msg.LocalFHIRInteropResponse, httpStatus As %String, message As %String) As %Status
{
	set message = $GET(message, "An internal error has occurred")
	$$$LOGERROR(message)

	return ..WriteResponse(Response, ##class(HS.FHIRServer.Util.Outcome).Create("error", message, "invalid"), httpStatus)
}

/// Returns a formatted OperationOutcome
ClassMethod WriteStatusResponse(Response As WEZORG.Msg.LocalFHIRInteropResponse, sc As %Status, targetHttpStatus As %String = 0) As %Status
{
	$$$LOGERROR($SYSTEM.Status.GetErrorText(sc))

	set outcome = ##class(HS.FHIRServer.Util.Outcome).CreateFromStatus(sc, .httpStatus)

	if (targetHttpStatus = 0)
	{
		set targetHttpStatus = httpStatus
	}

	return ..WriteResponse(Response, outcome, targetHttpStatus)
}

/// Write a proper response after sending it to the trace operation
ClassMethod WriteResponse(pResponse As WEZORG.Msg.LocalFHIRInteropResponse, resource As %DynamicObject, httpStatus As %String = 200) As %Status
{
	set pResponse.Response.Status = ##class(WEZORG.Util.HTTPStatusHelper).GetHTTPStatusCode(httpStatus)

	if $ISOBJECT(resource)
	{
		do ##class(WEZORG.Util.FHIRServerHelper).ValidateResource(resource)

		set quickStreamOut = ##class(HS.SDA3.QuickStream).%New()
		set pResponse.QuickStreamId = quickStreamOut.%Id()
		do ..JsonToStream(resource, pResponse.Response.ResponseFormatCode, 1, quickStreamOut, pResponse)

		do pResponse.SendQuickStreamToHSTrace(quickStreamOut, '##class(WEZORG.Util.HTTPStatusHelper).HTTPStatusIsOK(httpStatus))
	}

	return $$$OK
}

Storage Default
{
<Data name="GenericFHIRFacadeDefaultData">
<Subscript>"GenericFHIRFacade"</Subscript>
<Value name="1">
<Value>TraceOperations</Value>
</Value>
<Value name="2">
<Value>RavenDB</Value>
</Value>
<Value name="3">
<Value>Timeout</Value>
</Value>
</Data>
<DefaultData>GenericFHIRFacadeDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
