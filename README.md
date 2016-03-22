
- **search_repo**:  
	by `curl -s https://index.docker.io/v1/search?q={SEARCH_KEYWORD}&n=100&page={PAGE}`  
	[detail...](doc/search_repo.md)
	>result sample:

		{
		  "num_pages": 1,
		  "num_results": 50,
		  "results": [
		    {
		      "is_automated": true,
		      "name": "xjchengo/toran",
		      "is_trusted": true,
		      "is_official": false,
		      "star_count": 0,
		      "description": ""
		    },
				...
			]
		}

- **list_repo**:  
	by `curl -s https://hub.docker.com/v2/repositories/{NAMESPACE}/?page_size=${PAGE_SIZE}&page={PAGE}`  
	[detail...](doc/list_repo.md)  
	>result sample:

		{
		  "next": "https://hub.docker.com/v2/repositories/bluemeric/?page=3&page_size=100",
		  "previous": "https://hub.docker.com/v2/repositories/bluemeric/?page=1&page_size=100",
		  "results": [
		    {
		      "user": "bluemeric",
		      "name": "tt_tomcat",
		      "namespace": "bluemeric",
		      "status": 1,
		      "description": "",
		      "is_private": false,
		      "is_automated": false,
		      "can_edit": false,
		      "star_count": 0,
		      "pull_count": 16,
		      "last_updated": "2015-11-14T11:45:23.807030Z"
		    },
				...
			]
		}

- **list_tag**:  
	by `curl -s https://registry.hub.docker.com/v2/repositories/{REPO_NAME}/tags/`  
	[detail...](doc/list_tag.md)  
	>result sample:

		{
		  "count": 88,
		  "next": "https://registry.hub.docker.com/v2/repositories/library/ubuntu/tags/?page=2",
		  "previous": null,
		  "results": [
		    {
		      "name": "xenial",
		      "full_size": 47439662,
		      "id": 1589976,
		      "repository": 130,
		      "creator": 2215,
		      "last_updater": 2215,
		      "last_updated": "2016-01-04T19:00:51.344198Z",
		      "image_id": null,
		      "v2": true
		    },
				...
			]
		}

- **get tag**
```
curl -s https://index.docker.io/v1/repositories/library/ubuntu/tags | jq .
[
  {
    "layer": "ab035c88",
    "name": "latest"
  },
  {
    "layer": "3db9c44f",
    "name": "10.04"
  },
  {
    "layer": "33eb06bb",
    "name": "12.04"
```
