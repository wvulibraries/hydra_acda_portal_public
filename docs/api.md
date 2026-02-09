# API Reference

This document describes the APIs available in the ACDA Portal.

## OAI-PMH API

The portal provides OAI-PMH (Open Archives Initiative Protocol for Metadata Harvesting) support for metadata aggregation.

### Endpoint

- **Development**: `http://localhost:3000/catalog/oai`
- **Production**: `https://congressarchives.org/catalog/oai`

### Supported Verbs

- **Identify** - Repository information
- **ListMetadataFormats** - Available metadata formats
- **ListSets** - Available collections/sets
- **ListIdentifiers** - Record identifiers
- **ListRecords** - Full record metadata
- **GetRecord** - Individual record

### Metadata Formats

- **oai_dc** - Dublin Core metadata
- **mods** - MODS metadata (if configured)

### Example Requests

```bash
# Identify repository
curl "http://localhost:3000/catalog/oai?verb=Identify"

# List available metadata formats
curl "http://localhost:3000/catalog/oai?verb=ListMetadataFormats"

# List records (Dublin Core)
curl "http://localhost:3000/catalog/oai?verb=ListRecords&metadataPrefix=oai_dc"
```

### Configuration

OAI-PMH settings are configured in `hydra/app/controllers/catalog_controller.rb`:

```ruby
configure_blacklight do |config|
  # OAI-PMH configuration
  config.oai = {
    provider: {
      repository_name: 'American Congress Digital Archives',
      repository_url: 'https://congressarchives.org',
      record_prefix: 'oai:congressarchives',
      admin_email: 'admin@congressarchives.org',
      sample_id: '123456'
    },
    document: {
      limit: 100,
      set_model: MySetModel,
      set_fields: [{ label: 'collection', solr_field: 'collection_ssi' }]
    }
  }
end
```

## REST API (Limited)

The application primarily uses Rails views but exposes some RESTful endpoints.

### Authentication

Most endpoints require authentication. Use HTTP Basic Auth or session cookies.

### Endpoints

#### Collections
- `GET /collections` - List collections
- `GET /collections/:id` - Show collection details

#### Items
- `GET /catalog` - Search/browse items
- `GET /catalog/:id` - Show item details
- `GET /catalog/:id/manifest` - IIIF manifest (if applicable)

#### Files
- `GET /downloads/:id` - Download file
- `GET /images/:id` - View image
- `GET /pdf/:id` - View PDF

### Search API

Blacklight provides search API endpoints:

```bash
# JSON search results
curl "http://localhost:3000/catalog.json?q=congress"

# RSS feed
curl "http://localhost:3000/catalog.rss?q=foreign+policy"
```

### Parameters

- `q` - Search query
- `f[FIELD][]` - Facet filters
- `sort` - Sort field
- `per_page` - Results per page
- `page` - Page number

## Bulkrax API

For programmatic imports, Bulkrax provides API endpoints.

### Authentication Required

Use admin credentials for import operations.

### Endpoints

- `GET /importers` - List importers
- `POST /importers` - Create importer
- `GET /importers/:id` - Show importer status
- `PUT /importers/:id` - Update importer
- `DELETE /importers/:id` - Delete importer

### Import Workflow

1. Create importer with CSV/metadata configuration
2. Upload data files
3. Start import job
4. Monitor progress via API or UI

## Webhooks (Future)

Webhooks for real-time notifications are planned for future releases.

## Rate Limiting

- OAI-PMH: 1000 requests per hour per IP
- Search API: 100 requests per minute per IP
- File downloads: 10 concurrent downloads per IP

## Error Handling

All APIs return standard HTTP status codes:

- `200` - Success
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

Error responses include JSON with error details:

```json
{
  "error": "Invalid request",
  "message": "Missing required parameter: q",
  "code": 400
}
```

## SDKs and Libraries

No official SDKs are currently available. Use standard HTTP libraries:

- **Python**: `requests`
- **Ruby**: `net/http` or `faraday`
- **JavaScript**: `fetch` or `axios`

## Support

For API support or questions:
- Check the [troubleshooting guide](troubleshooting.md)
- Review [development documentation](development.md)
- Contact the development team