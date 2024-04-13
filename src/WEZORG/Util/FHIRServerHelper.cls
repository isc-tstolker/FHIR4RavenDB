Include (HS.FHIRServer, Ensemble)

/// Utility Functions for FHIR Server
Class WEZORG.Util.FHIRServerHelper Extends WEZORG.Util.FHIRJsonHelper
{

/// FHIR Version supported
Parameter FHIRVERSION As %String = "R4";

/// Get Schema for the right FHIR version
ClassMethod GetSchema() As HS.FHIRServer.Schema
{
    return ##class(HS.FHIRServer.Schema).LoadSchema(..#FHIRVERSION)
}

/// ValidateResource validates a FHIR Resource.  If a validation error is found, a
/// compound %Status is thrown in a StatusException.  The compound %Status starts with a
/// $$$ValidationFailure code, followed by additional %Status objects for each detected
/// validation error.
/// Inputs:
/// <li>pJsonResource           : (required) %DynamicObject representation of the FHIR resource.
/// <li>Throws					: A StatusException containing a compound %Status representing all
///                             : validation errors.
ClassMethod ValidateResource(resource As %DynamicObject)
{
	#dim validator as HS.FHIRServer.Util.ResourceValidator = ##class(HS.FHIRServer.Util.ResourceValidator).%New(..GetSchema())

	do validator.ValidateResource(resource)
}

/// GetResourceFromRequest
ClassMethod GetResourceFromRequest(pRequest As WEZORG.Msg.LocalFHIRInteropRequest) As %DynamicObject
{
	set resource = ..QuickStreamToJSON(pRequest.QuickStreamId, pRequest.Request.RequestFormatCode)

	if resource = ""
	{ 
		$$$ThrowFHIR($$$HSFHIRErrPayloadMissing, pRequest.Request.RequestMethod _ " " _ pRequest.ResourceType, $$$OutcomeIs(400, "error", "required"))
	}

	if resource.resourceType '= pRequest.ResourceType
	{ 
		$$$ThrowFHIR($$$HSFHIRErrPayloadTypeMismatch, resource.resourceType, pRequest.ResourceType, $$$OutcomeInvalid(400))
	}

	do ##class(WEZORG.Util.FHIRServerHelper).ValidateResource(resource)

	return resource
}

/// QuickStreamToJSON transforms the incoming request to a JSON DynamicObject, whether it is XML or JSON
ClassMethod QuickStreamToJSON(quickStreamId As %String, requestFormatCode As %String) As %DynamicObject
{
	if (quickStreamId '= "")
	{
		set quickStreamIn = ##class(HS.SDA3.QuickStream).%OpenId(quickStreamId, , .sc)
		
		if $$$ISERR(sc)
		{
			return ""
		}

		return ..StreamToJSON(quickStreamIn, requestFormatCode)
	}

	return ""
}

/// StreamToJSON is a helper method that transforms an incoming request in eiither XML or JSON to a DynamicObject
ClassMethod StreamToJSON(pStream As %Stream.Object, pContentCode As %String) As %DynamicObject
{
	if 'pStream.Size
	{
		$$$ThrowStatus($$$ERROR($$$HSFHIRErrAPIContractViolation, "Blank FHIR stream specified") )
	}
	
	if ((pContentCode = $$$FHIRContentCodeJSON ) || (pContentCode = $$$FHIRContentCodeJPatch))
	{
		set json = ##class(HS.FHIRServer.Util.JsonHelper).FromJSON(pStream)
		return json
	}
	elseif (pContentCode = $$$FHIRContentCodeXML )
	{
		// Skip the <?xml ... ?> header of any
		// If the request body is XML, strip off the XML prolog, if present.
		// Any encoded characters have already been converted to internal format
		// (by virtue of having CONVERTINPUTSTREAM=1). Having the XML prolog, if it
		// contains "encoding='UTF-8'", will cause XML parsing to error, as it will
		// try to convert the already-converted characters.
		if (pStream.Read(5) = "<?xml")
		{
			// Has a prolog, read to the end of it.
			while ('pStream.AtEnd) && (pStream.Read(1) '= ">")  { }
			// Write a new stream from the remainder of the original stream.
			set tempStream = ##class(%Stream.TmpCharacter).%New()
			while ('pStream.AtEnd)  {
				do tempStream.Write(pStream.Read())
			}
		}
		else
		{
			set tempStream = pStream
		}

		do tempStream.Rewind()

		return ##class(HS.FHIRServer.Util.XMLToJSON).XMLToJSON(.tempStream, ..GetSchema())
	}
	else
	{
		$$$ThrowFHIR($$$HSFHIRErrInvalidContentCode, pContentCode)
	}
}

/// Based on ##class(HS.FHIRServer.RestHandler).WriteResponse()
ClassMethod JsonToStream(json As %DynamicObject = "", pResponseFormatCode As %String, isPretty As %Boolean, pOutStream As %Stream.Object, pInteropResponse As HS.FHIRServer.Interop.Response)
{
	if $ISOBJECT(json)
	{
		// Set the Mime Headers in the response if there is content
		do ##class(HS.FHIRServer.RestHandler).GetResponseMimeType(pResponseFormatCode , .pInteropResponse)
		
		if isPretty {
			set indent = "  "
			set lineEnd = $CHAR(13,10)
		} else {
			set indent = ""
			set lineEnd = ""
		}

		// Write the content
		if (pResponseFormatCode = $$$FHIRContentCodeXML)
		{
			// Output as XML
			do ##class(HS.FHIRServer.Util.JSONToXML).JSONToXML(json, .pOutStream, ..GetSchema(), indent, lineEnd)
		}
		else
		{
			// Output as JSON
			do ##class(HS.FHIRServer.Util.JsonHelper).ToJSONStream(json, .pOutStream, indent, lineEnd)
		}
	}
}

}
