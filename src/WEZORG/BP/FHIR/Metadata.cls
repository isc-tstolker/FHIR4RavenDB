/// AeoNose-specific FHIR facade - adds AeoNose-specific Metadata to the Generic FHIR Facade
Class WEZORG.BP.FHIR.Metadata
{

/// HandleMetadata
Method HandleMetadata(pRequest As WEZORG.Msg.LocalFHIRInteropRequest, pInteropResponse As HS.FHIRServer.Interop.Response) As %Status
{
	set capabilityStatement = {
		"resourceType": "CapabilityStatement",
		"id": "InterSystemsFHIRServer",
		"meta": {
			"lastUpdated": "2023-02-15T16:45:00+01:00",
			"versionId": "4"
		},
		"url": "https://enose-company.com/fhir/CapabilityStatement/WEZORG",
		"version": "1",
		"name": "WEZORG FHIR API",
		"status": "active",
		"experimental": false,
		"date": "2023-02-15T16:43:00+01:00",
		"publisher": "eNose Company",
		"kind": "instance",
		"software": {
			"name": "WEZORG based on InterSystems IRIS for Health",
			"version": "0.1"
		},
		"implementation": {
			"description": "WEZORG Facade",
			"url": (pRequest.Request.BaseURL)
		},
		"fhirVersion": "4.0.1",
		"format": [
			"xml",
			"json"
		],
		"rest": [
			{
				"mode": "server",
				"resource": [
					{
						"type": "ServiceRequest",
						"versioning": "no-version",
						"readHistory": false,
						"updateCreate": false,
						"conditionalCreate": false,
						"conditionalUpdate": false,
						"conditionalDelete": "not-supported",
						"interaction": [
							{
								"code": "read"
							},
							{
								"code": "create"
							},
							{
								"code": "update"
							},
							{
								"code": "delete"
							},
							{
								"code": "search-type"
							}
						],
						"searchParam": [
							{
								"name": "identifier",
								"type": "token"
							},
							{
								"name": "authored",
								"type": "date"
							},
							{
								"name": "occurrence",
								"type": "date"
							},
							{
								"name": "patient",
								"type": "reference"
							},
							{
								"name": "status",
								"type": "token"
							},
							{
								"name": "subject",
								"type": "reference"
							}
						]
					}
				],
				"searchParam": [
					{
						"name": "_id",
						"type": "token"
					}
				]
			}
		]
	}

	return ##class(WEZORG.BP.FHIR.GenericFacade).WriteResponse(.pInteropResponse, capabilityStatement)
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
