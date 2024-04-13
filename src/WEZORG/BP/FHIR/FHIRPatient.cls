/// FHIR R4 Patient mapping from RavenDB
Class WEZORG.BP.FHIR.FHIRPatient Extends WEZORG.BP.FHIR.GenericFacade
{

/// Handle Patient search and read
Method HandlePatientGet(pRequest As WEZORG.Msg.LocalFHIRInteropRequest, pResponse As WEZORG.Msg.LocalFHIRInteropResponse) As %Status
{
	if (pRequest.ResourceId '= "")
	{
		set resource = ..HandlePatientRead(pRequest.ResourceType, pRequest.ResourceId)
	}
	else
	{
		set resource = ..HandlePatientSearch(pRequest, pResponse)
	}

	return ##class(WEZORG.BP.FHIR.GenericFacade).WriteResponse(pResponse, resource)
}

/// HandlePatient read
Method HandlePatientRead(resourceType As %String, resourceId As %String) As %DynamicObject
{
	// Get Patient from RavenDB
	set dbPatient = "" 
	
	if dbPatient = ""
	{
		$$$ThrowFHIR($$$HSFHIRErrResourceNotFound, resourceType, resourceId, $$$OutcomeInvalid(404))
	}

	return ..CreatePatientFromDB(dbPatient)
}

/// Get FHIR Patient for the specified dbPatient
Method CreatePatientFromDB(dbPatient As %DynamicObject) As %DynamicObject
{
	set patient = {
		"resourceType": "Patient",
		"id": (dbPatient."@metadata"."@id"),
		"meta": {
			"lastUpdated": (dbPatient."@metadata"."@last-modified")
		},
		"name": [
			{
				"given": [ (dbPatient.Name.First) ],
				"family": (dbPatient.Name.Last)
			}
		],
		"telecom": (..GetTelecoms(dbPatient))
	}

	return patient
}

/// Get telecoms from RavenDB Patient document
Method GetTelecoms(dbPatient As %DynamicObject) As %DynamicArray
{
	return []
}

///  Search is supported on _id and would be nice on authored, identifier, patient/subject, status and occurrence as well
/// _sort is supported on: authored, occurrence
ClassMethod ProcessQueryString(queryString As %String) As %String
{
	set whereClause = ""

	for index = 1:1:$LENGTH(queryString, "&")
	{
		set queryPart = $PIECE(queryString, "&", index)
		set varnameWithModifier = $PIECE(queryPart, "=", 1)
		set varname = $PIECE(varnameWithModifier, ":", 1)
		set searchValue = $PIECE(queryPart, "=", 2)

		do ..AddToWhereClause(.whereClause, varname, $PIECE(varnameWithModifier, ":", 2), searchValue)
	}

	return whereClause
}

/// Add to where clause
ClassMethod AddToWhereClause(ByRef whereClause As %String, varname As %String, modifier As %String, searchValue As %String)
{
}

/// HandlePatient search
Method HandlePatientSearch(pRequest As WEZORG.Msg.LocalFHIRInteropRequest, pResponse As WEZORG.Msg.LocalFHIRInteropResponse) As %DynamicObject
{
	// Return selected Order(s) as ServiceOrders
	set self = pRequest.Request.BaseURL _ "/" _ pRequest.Request.RequestPath
	set whereAndOrderByClause = ""

	if pRequest.Request.QueryString '= ""
	{
		set self = self _ "?" _ pRequest.Request.QueryString
		set whereAndOrderByClause = ..ProcessQueryString(pRequest.Request.QueryString)
	}

	set bundle = {
		"resourceType": "Bundle",
		"id": ($ZCONVERT($SYSTEM.Util.CreateGUID(), "l")),
		"type": "searchset",
		"timestamp": ($ZDATETIME($HOROLOG, 3, 5)),
		"total": 0,
		"link": [
			{
				"relation": "self",
				"url": (self)
			}
		]
	}

	#dim entries as %DynamicArray = []

	// Now get Patient from RavenDB

	for orderIndex = 1:1:orders.Count()
	{
		#dim dbPatient as %DynamicObject = {}

		do entries.%Push( {
			"fullUrl": (pRequest.Request.BaseURL _ "/" _ pRequest.ResourceType _ "/" _ dbPatient.OrderId),
			"resource": (..CreatePatientFromDB(dbPatient))
			} )
	}

	if (entries.%Size() > 0)
	{
		set bundle.total = entries.%Size()
		set bundle.entry = entries
	}

	return bundle
}

Method RavenDbQuery(query As %String) As %DynamicObject
{
	set request = ##class(WEZORG.Msg.RavenDB.QueryRequest).%New()

	$$$ThrowOnError(..SendRequestSync(..RavenDB, request, .response))

	#dim response as WEZORG.Msg.RavenDB.QueryResponse
	return response.Result()
}

/// HandlePatient update
Method HandlePatientPut(pRequest As WEZORG.Msg.LocalFHIRInteropRequest, pResponse As WEZORG.Msg.LocalFHIRInteropResponse) As %Status
{
	#; set Patient = ..GetResourceFromRequest(pRequest)

	#; if Patient.id '= pRequest.ResourceId	// Check Id
	#; {
	#; 	$$$ThrowFHIR($$$HSFHIRErrInvalidUpdateId, $$$OutcomeInvalid(400))
	#; }
	
	#; set dbPatient = ##class(WEZORG.DB.Order).ByOrderId(pRequest.ResourceId)
	
	#; if dbPatient = ""
	#; {
	#; 	$$$ThrowFHIR($$$HSFHIRErrResourceNotFound, pRequest.ResourceType, pRequest.ResourceId, $$$OutcomeNotFound)
	#; }

	#; return ..CreateOrUpdatePatient(pRequest, Patient, dbPatient, pResponse, "update")

	$$$ThrowFHIR($$$HSFHIRErrOperationNotSupported, pRequest.ResourceType, pRequest.ResourceId, $$$OutcomeNotFound)
}

/// HandlePatient create
Method HandlePatientPost(pRequest As WEZORG.Msg.LocalFHIRInteropRequest, pResponse As WEZORG.Msg.LocalFHIRInteropResponse) As %Status
{
	#; set Patient = ..GetResourceFromRequest(pRequest)

	$$$ThrowFHIR($$$HSFHIRErrOperationNotSupported, pRequest.ResourceType, pRequest.ResourceId, $$$OutcomeNotFound)
}

/// Handle Patient Delete as if it was cancelled
Method HandlePatientDelete(pRequest As WEZORG.Msg.LocalFHIRInteropRequest, pResponse As WEZORG.Msg.LocalFHIRInteropResponse) As %Status
{
	#; if (pRequest.ResourceId '= "")
	#; {
	#; 	#dim dbPatient as WEZORG.DB.Order = ##class(WEZORG.DB.Order).ByOrderId(pRequest.ResourceId)
		
	#; 	if (dbPatient '= "") && (dbPatient.Status '= "cancelled")
	#; 	{
	#; 		// Update to cancelled status via ProcessWorkOrder process

	#; 		set Patient = ..CreatePatientFromDB(dbPatient)

	#; 		set Patient.status = "revoked"

	#; 		return ..SendPatientAsOrderRequestAndHandleResponse(pRequest, Patient, dbPatient.ExternalOrderID, pResponse, "delete")
	#; 	}

	#; 	set pResponse.Response.Status = ##class(%CSP.REST).#HTTP204NOCONTENT

	#; 	return $$$OK
	#; }

	#; $$$ThrowFHIR($$$HSFHIRErrConditionalDeleteNotSupported, pRequest.ResourceType, $$$OutcomeInvalid(404))

	$$$ThrowFHIR($$$HSFHIRErrOperationNotSupported, pRequest.ResourceType, pRequest.ResourceId, $$$OutcomeNotFound)
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
