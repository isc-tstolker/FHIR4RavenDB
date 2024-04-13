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
	set result = ..RavenDbGetById(resourceId)
	set dbPatient = ""

	if $ISOBJECT(result)
	{
		set dbPatient = result.Results.%Get(0)		
	}

	if '$ISOBJECT(dbPatient)
	{
		$$$ThrowFHIR($$$HSFHIRErrResourceNotFound, resourceType, resourceId, $$$OutcomeInvalid(404))
	}

	return ..CreatePatientFromDB(dbPatient)
}

/// Query RavenDB
Method RavenDbGetById(id As %String) As %DynamicObject
{
	set request = ##class(WEZORG.Msg.RavenDB.GetDocumentRequest).%New()
	set request.pathdb = "wezorg"
	set request.queryid = id

	$$$ThrowOnError(..SendRequestSync(..RavenDB, request, .response))

	#dim response as WEZORG.Msg.RavenDB.QueryResponse
	return response.Result()
}

/// Get FHIR Patient for the specified dbPatient
Method CreatePatientFromDB1(dbPatient As %DynamicObject) As %DynamicObject
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
		]
	}

	if $ISOBJECT(dbPatient.Telecoms)
	{
		#dim telecoms as %DynamicArray = []
		set patient.telecom = telecoms

		for index = 1:1:dbPatient.Telecoms.%Size()
		{
			#dim telecom as %DynamicObject = dbPatient.Telecoms.%Get(index - 1)

			do telecoms.%Push({
				"system": (telecom.use),
				"value": (telecom.value)
			})
		}
	}

	return patient
}

/// Get FHIR Patient for the specified dbPatient
Method CreatePatientFromDB(dbPatient As %DynamicObject) As %DynamicObject
{
	set patient = ##class(HS.FHIRModel.R4.Patient).%New()
	set patient.fhirID = dbPatient."@metadata"."@id"
	do patient.IncludeMeta()
	set patient.meta.lastUpdated = dbPatient."@metadata"."@last-modified"
	do patient.IncludeName()

	set name = ##class(HS.FHIRModel.R4.HumanName).%New()
	do name.IncludeGiven()
	do name.given.add(dbPatient.Name.First)
	set name.family = dbPatient.Name.Last
	do patient.name.add(name)

	do ..GetTelecoms(patient, dbPatient)

	return patient.toDao()
}

/// Get telecoms from RavenDB Patient document
Method GetTelecoms(patient As HS.FHIRModel.R4.Patient, dbPatient As %DynamicObject)
{
	if $ISOBJECT(dbPatient.Telecoms)
	{
		do patient.IncludeTelecom()

		for index = 1:1:dbPatient.Telecoms.%Size()
		{
			#dim telecom as %DynamicObject = dbPatient.Telecoms.%Get(index - 1)
			set contactPoint = ##class(HS.FHIRModel.R4.ContactPoint).%New()
			set contactPoint.system = telecom.use
			set contactPoint.value = telecom.value

			do patient.telecom.add(contactPoint)
		}
	}
}

///  Search is supported on _id
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
	set columnName =$CASE(varname, "_id":"id()", :"")

	if (columnName '= "")
	{
		if whereClause = ""
		{
			set whereClause = whereClause _ " where "
		}
		else
		{
			set whereClause = whereClause _ " AND "
		}

		set whereClause = whereClause _ columnName

		if (modifier = "not")
		{
			set whereClause = whereClause _ " not"
		}

		set whereClause = whereClause _ " in ('" _ searchValue_ "')"
	}
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

	#dim result as %DynamicObject = ..RavenDbQuery("from @all_docs " _  whereAndOrderByClause)

	for index = 1:1:result.Results.%Size()
	{
		#dim dbPatient as %DynamicObject = result.Results.%Get(index - 1)

		do entries.%Push( {
			"fullUrl": (pRequest.Request.BaseURL _ "/" _ pRequest.ResourceType _ "/" _ dbPatient."@metadata"."@id"),
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

/// Query RavenDB
Method RavenDbQuery(query As %String = "from @all_docs") As %DynamicObject
{
	set request = ##class(WEZORG.Msg.RavenDB.QueryRequest).%New()
	set request.pathdb = "wezorg"
	set request.Query.Query = query

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
