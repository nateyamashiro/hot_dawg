---
title: "Data store error codes and limits"
url: /docs/en-us/cloud-services/data-stores/error-codes-and-limits
last_updated: 2026-07-02T02:14:27Z
description: "Error codes you might encounter and limits you might hit when using data stores (DataStores) to store data."
---

# Data store error codes and limits

Requests you make to data stores can fail due to poor connectivity or other issues. To handle errors and return messages with an error code, wrap data store functions in `Global.LuaGlobals.pcall()`.

A failed write call, such as `Class.GlobalDataStore:UpdateAsync()|UpdateAsync()`, means the game server did not receive a successful response. It does not always guarantee that the backend write did not occur. In some failure scenarios, the final write state may be unknown to the caller until it is verified with a follow-up read without cache.

## Error code reference

| Error code | Error name | Error message | Notes |
| --- | --- | --- | --- |
| `101` | `KeyNameEmpty` | Key name can't be empty. | Check if the key input into the data store function is an empty string. |
| `102` | `KeyNameLimit` | Key name exceeds the 50 character limit. | Check if the key input into the data store function exceeds a length of 50. |
| `103` | `ValueNotAllowed` | Can't allow **X** in `DataStore`. | A bad update function returned a value of type **X**. |
| `104` | `CantStoreValue` | Can't store **X** in `DataStore`. | The update function returned a value of type **X** that didn't serialize. |
| `105` | `ValueTooLarge` | Serialized value exceeds **X** limit. | If you're setting a value with `Class.GlobalDataStore:SetAsync()\|SetAsync()` or `Class.GlobalDataStore:UpdateAsync()\|UpdateAsync()`, the serialized length of the value can't exceed the size **X**. To check the serialized length of the data, use `Class.HttpService:JSONEncode()\|JSONEncode()`. |
| `106` | `MaxValueInvalid` | `MaxValue` must be an integer. | If you're passing a maximum value to `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` for an `Class.OrderedDataStore`, it must be an integer. |
| `106` | `MinValueInvalid` | `MinValue` must be an integer. | If you're passing a minimum value to `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` for an `Class.OrderedDataStore`, it must be an integer. |
| `106` | `PageSizeGreater` | `PageSize` must be within a predefined range. | The minimum page size for an `Class.OrderedDataStore` is 1. |
| `106` | `PageSizeLesser` | `PageSize` must be within a predefined range. | The maximum page size for an `Class.OrderedDataStore` is 100. |
| `107` | `MinMaxOrderInvalid` | `MaxValue` must be greater than or equal to `MinValue`. | The maximum value must be greater than or equal to the minimum value for `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()`. |
| `301` | `GetAsyncThrottle` | `GetAsync` request dropped. Request was throttled but queue was full. | `Class.GlobalDataStore:GetAsync()\|GetAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `302` | `SetAsyncThrottle` | `SetAsync` request dropped. Request was throttled but queue was full. | `Class.GlobalDataStore:SetAsync()\|SetAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `303` | `IncreAsyncThrottle` | `IncrementAsync` request dropped. Request was throttled but queue was full. | `Class.GlobalDataStore:IncrementAsync()\|IncrementAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `304` | `UpdateAsyncThrottle` | `UpdateAsync` request dropped. Request was throttled but queue was full. | `Class.GlobalDataStore:UpdateAsync()\|UpdateAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `304` | `TransformThrottle` | `UpdateAsync` request dropped. Request was throttled but queue was full. | `Class.GlobalDataStore:UpdateAsync()\|UpdateAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `305` | `GetSortedThrottle` | `GetSorted` request dropped. Request was throttled but queue was full. | `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `306` | `RemoveAsyncThrottle` | `RemoveAsync` request dropped. Request was throttled but queue was full. | `Class.GlobalDataStore:RemoveAsync()\|RemoveAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
| `401` | `DataModelNoAccess` | Request failed. `DataModel` is inaccessible while the experience is shutting down. | `Class.DataModel` is uninitialized because the experience is shutting down. |
| `402` | `LuaWebSrvsNoAccess` | Request failed. `LuaWebService` is inaccessible while the experience is shutting down. | `Class.LuaWebService` is uninitialized because the experience is shutting down. |
| `403` | `StudioAccessToApisNotAllowed` | Can't write to `DataStore` from Studio because API access is not enabled. | API access must be active in order to use data stores in Studio. |
| `404` | `InternalError` | `OrderedDataStore` doesn't exist. | The `Class.OrderedDataStore` associated with this request wasn't found. This might be a sign of data corruption. Try again later. |
| `501` | `InternalError` | Can't parse response because data might be corrupted. | The server was unable to parse the response to your request. This might be a sign of data corruption. Try again later. |
| `502` | `RequestRejected` | API Services rejected the request with error **X**. | Error **X** occurred when processing on Roblox servers. Try again later. |
| `503` | `InternalError` | Data store request was successful but key wasn't found. | The key requested wasn't found in the data store. This might be a sign of data corruption. Try again later. |
| `504` | `InternalError` | Data store request was successful but the response wasn't formatted correctly. | The server was unable to parse the response to your request. This might be a sign of data corruption. Try again later. |
| `505` | `InternalError` | `OrderedDataStore` request was successful but the response wasn't formatted correctly. | The server was unable to parse the response to your `Class.OrderedDataStore` request. This might be a sign of data corruption. Try again later. |
| `509` | `OperationNotAllowed` | Data store operations are blocked while running on a Personal RCC to prevent possible data corruption. | Data store writes are blocked on private RCC channels. |
| `511` | `AttributeSizeTooLarge` | Metadata attribute size exceeds **X** limit. | The serialized metadata size exceeds the limit of **X**. The value **X** is dynamic. If the size changes, the value also changes. |
| `512` | `UserIdLimitExceeded` | `UserID` size exceeds **X** limit. | The length of the user IDs array provided by the user exceeds the limit of **X**. |
| `513` | `AttributeFormatError` | Attribute `userId` format is invalid. | The user ID provided isn't a number. |
| `513` | `AttributeFormatError` | Attribute metadata format is invalid. | The metadata isn't a table. |
|  | `GetVersionAsyncThrottle` | `GetVersionAsync` request dropped. Request was throttled. | `Class.DataStore:GetVersionAsync()\|GetVersionAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
|  | `GetVersionAtTimeAsyncThrottle` | `GetVersionAtTimeAsync` request dropped. Request was throttled. | `Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
|  | `ListDataStoresAsyncThrottle` | `ListDataStoresAsync` request dropped. Request was throttled. | `Class.DataStoreService:ListDataStoresAsync()\|ListDataStoresAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
|  | `ListKeysAsyncThrottle` | `ListKeysAsync` request dropped. Request was throttled. | `Class.DataStore:ListKeysAsync()\|ListKeysAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
|  | `ListVersionsAsyncThrottle` | `ListVersionsAsync` request dropped. Request was throttled. | `Class.DataStore:ListVersionsAsync()\|ListVersionsAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. |
|  | `RemoveVersionAsyncThrottle` | `RemoveVersionAsync` request dropped. Request was throttled. | `Class.DataStore:RemoveVersionAsync()\|RemoveVersionAsync()` request has exceeded the maximum queue size and Roblox is unable to process the requests at the current throughput. | |
|  | `InvalidTimestamp` | Timestamp must be positive and not more than ten minutes in the future. | The timestamp provided to `Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()` was not valid. | |
|  | `StandardReadExperienceThrottled` | `StandardRead` request was throttled by experience limits. | A request to `Class.DataStore:GetAsync()\|GetAsync()`, `Class.DataStore:GetVersionAsync()\|GetVersionAsync()`, `Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()`, or the read of `Class.DataStore:UpdateAsync()\|UpdateAsync()` on a standard data store exceeded the `StandardRead` experience-level rate limit. |
|  | `StandardWriteExperienceThrottled` | `StandardWrite` request was throttled by experience limits. | A request to `Class.DataStore:SetAsync()\|SetAsync()`, `Class.DataStore:IncrementAsync()\|IncrementAsync()`, or the write of `Class.DataStore:UpdateAsync()\|UpdateAsync()` on a standard data store exceeded the `StandardWrite` experience-level rate limit. |
|  | `StandardListExperienceThrottled` | `StandardList` request was throttled by experience limits. | A request to `Class.DataStore:ListKeysAsync()\|ListKeysAsync()`, `Class.DataStore:ListVersionsAsync()\|ListVersionsAsync()`, or `Class.DataStoreService:ListDataStoresAsync()\|ListDataStoresAsync()` on standard data stores exceeded the `StandardList` experience-level rate limit. |
|  | `StandardRemoveExperienceThrottled` | `StandardRemove` request was throttled by experience limits. | A request to `Class.DataStore:RemoveAsync()\|RemoveAsync()` on a standard data store exceeded the `StandardRemove` experience-level rate limit. |
|  | `OrderedReadExperienceThrottled` | `OrderedRead` request was throttled by experience limits. | A request to `Class.OrderedDataStore:GetAsync()\|GetAsync()` or the read of `Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` on an ordered data store exceeded the `OrderedRead` experience-level rate limit. |
|  | `OrderedWriteExperienceThrottled` | `OrderedWrite` request was throttled by experience limits. | A request to `Class.OrderedDataStore:SetAsync()\|SetAsync()`, `Class.OrderedDataStore:IncrementAsync()\|IncrementAsync()`, or the write of `Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` on an ordered data store exceeded the `OrderedWrite` experience-level rate limit. |
|  | `OrderedListExperienceThrottled` | `OrderedList` request was throttled by experience limits. | A request to `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` on an ordered data store exceeded the `OrderedList` experience-level rate limit. |
|  | `OrderedRemoveExperienceThrottled` | `OrderedRemove` request was throttled by experience limits. | A request to `Class.OrderedDataStore:RemoveAsync()\|RemoveAsync()` on an ordered data store exceeded the `OrderedRemove` experience-level rate limit. |
|  | `StandardReadGameServerThrottled` | `StandardRead` request was throttled by game server limits or the request queue was full. | A request to `Class.DataStore:GetAsync()\|GetAsync()`, `Class.DataStore:GetVersionAsync()\|GetVersionAsync()`, `Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()`, or the read of `Class.DataStore:UpdateAsync()\|UpdateAsync()` on a standard data store exceeded the `StandardRead` game server-level rate limit. |
|  | `StandardWriteGameServerThrottled` | `StandardWrite` request was throttled by game server limits or the request queue was full. | A request to `Class.DataStore:SetAsync()\|SetAsync()`, `Class.DataStore:IncrementAsync()\|IncrementAsync()`, or the write of `Class.DataStore:UpdateAsync()\|UpdateAsync()` on a standard data store exceeded the `StandardWrite` game server-level rate limit. |
|  | `StandardListGameServerThrottled` | `StandardList` request was throttled by game server limits or the request queue was full. | A request to `Class.DataStore:ListKeysAsync()\|ListKeysAsync()`, `Class.DataStore:ListVersionsAsync()\|ListVersionsAsync()`, or `Class.DataStoreService:ListDataStoresAsync()\|ListDataStoresAsync()` on standard data stores exceeded the `StandardList` game server-level rate limit. |
|  | `StandardRemoveGameServerThrottled` | `StandardRemove` request was throttled by game server limits or the request queue was full. | A request to `Class.DataStore:RemoveAsync()\|RemoveAsync()` on a standard data store exceeded the `StandardRemove` game server-level rate limit. |
|  | `OrderedReadGameServerThrottled` | `OrderedRead` request was throttled by game server limits or the request queue was full. | A request to `Class.OrderedDataStore:GetAsync()\|GetAsync()` or the read of `Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` on an ordered data store exceeded the `OrderedRead` game server-level rate limit. |
|  | `OrderedWriteGameServerThrottled` | `OrderedWrite` request was throttled by game server limits or the request queue was full. | A request to `Class.OrderedDataStore:SetAsync()\|SetAsync()`, `Class.OrderedDataStore:IncrementAsync()\|IncrementAsync()`, or the write of `Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` on an ordered data store exceeded the `OrderedWrite` game server-level rate limit. |
|  | `OrderedListGameServerThrottled` | `OrderedList` request was throttled by game server limits or the request queue was full. | A request to `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` on an ordered data store exceeded the `OrderedList` game server-level rate limit. |
|  | `OrderedRemoveGameServerThrottled` | `OrderedRemove` request was throttled by game server limits or the request queue was full. | A request to `Class.OrderedDataStore:RemoveAsync()\|RemoveAsync()` on an ordered data store exceeded the `OrderedRemove` game server-level rate limit. |

### Server error codes

| Error name | Error message | Notes |
| --- | --- | --- |
| `DatastoreDeleted` | The data store is deleted. | An operation on the data store could not occur because the data store was previously deleted. |
| `DatastoreThrottled` | The request rate exceeds the allowed maximum for the `datastore`. | Too many requests were sent to a single data store. |
| `InternalServerError` | An internal server error occurred. | Occasional error on Roblox servers. Try again, ideally with exponential backoff. |
| `InvalidExclusiveStartKey` | The provided exclusive start key is not valid. | The exclusive start key (cursor) provided to a list operation such as `Class.DataStore:ListKeysAsync()\|ListKeysAsync()` is not valid. |
| `InvalidPlace` | The provided place is invalid. | No matching Universe ID for the place. Try again later. |
| `InvalidTarget` | The provided target is invalid. | Ordered data store key name exceeds the 50 character limit. |
| `InvalidUniverse` | The provided universe is invalid. | No matching Place ID for the universe. Try again later. |
| `InvalidUserIds` | The provided user IDs have an invalid format. | Failed to parse user IDs. |
| `KeyThrottled` | The request rate exceeds the allowed maximum for the key. | The request rate exceeds the maximum allowed request rate for a single key. |
| `KeyNotFound` | The requested key doesn't exist. | The key doesn't exist. |
| `N/A` | No pages to advance to. | This error occurs when you call `Class.Pages:AdvanceToNextPageAsync()` on the last page. |
| `StandardReadExperienceThrottled` | The standard read request rate exceeds the allowed maximum for the experience. | A request to `Class.DataStore:GetAsync()\|GetAsync()`, `Class.DataStore:GetVersionAsync()\|GetVersionAsync()`, `Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()`, or the read of `Class.DataStore:UpdateAsync()\|UpdateAsync()` on a standard data store exceeded the `StandardRead` experience-level rate limit. |
| `StandardWriteExperienceThrottled` | The standard write request rate exceeds the allowed maximum for the experience. | A request to `Class.DataStore:SetAsync()\|SetAsync()`, `Class.DataStore:IncrementAsync()\|IncrementAsync()`, or the write of `Class.DataStore:UpdateAsync()\|UpdateAsync()` on a standard data store exceeded the `StandardWrite` experience-level rate limit. |
| `StandardListExperienceThrottled` | The standard list request rate exceeds the allowed maximum for the experience. | A request to `Class.DataStore:ListKeysAsync()\|ListKeysAsync()`, `Class.DataStore:ListVersionsAsync()\|ListVersionsAsync()`, or `Class.DataStoreService:ListDataStoresAsync()\|ListDataStoresAsync()` on standard data stores exceeded the `StandardList` experience-level rate limit. |
| `StandardRemoveExperienceThrottled` | The standard remove request rate exceeds the allowed maximum for the experience. | A request to `Class.DataStore:RemoveAsync()\|RemoveAsync()` on a standard data store exceeded the `StandardRemove` experience-level rate limit. |
| `OrderedReadExperienceThrottled` | The ordered read request rate exceeds the allowed maximum for the experience. | A request to `Class.OrderedDataStore:GetAsync()\|GetAsync()` or the read of `Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` on an ordered data store exceeded the `OrderedRead` experience-level rate limit. |
| `OrderedWriteExperienceThrottled` | The ordered write request rate exceeds the allowed maximum for the experience. | A request to `Class.OrderedDataStore:SetAsync()\|SetAsync()`, `Class.OrderedDataStore:IncrementAsync()\|IncrementAsync()`, or the write of `Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` on an ordered data store exceeded the `OrderedWrite` experience-level rate limit. |
| `OrderedListExperienceThrottled` | The ordered list request rate exceeds the allowed maximum for the experience. | A request to `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` on an ordered data store exceeded the `OrderedList` experience-level rate limit. |
| `OrderedRemoveExperienceThrottled` | The ordered remove request rate exceeds the allowed maximum for the experience. | A request to `Class.OrderedDataStore:RemoveAsync()\|RemoveAsync()` on an ordered data store exceeded the `OrderedRemove` experience-level rate limit. |

## Limits

Data models have **limits**. If an experience exceeds these limits, the service automatically throttles the experience's data store usage and causes future requests to be placed in one of the following queues:

- Set
- Ordered set
- Get
- Ordered get

Requests in a queue are handled in the order they are received. The called function continues to yield as long as its request is still queued. If the data store key itself is throttled, the request is placed in a queue but is temporarily skipped.

Each queue has a limit of 30 requests. When the limit of a queue is reached, requests fail with an error code in the 301-306 range, indicating that the requests have been dropped entirely.

### Access limits

Data stores are subject to both **experience and server-level limits**. Experience-level limits scale with total concurrent users across the experience, while server-level limits are configurable and meant to be used as a tool by the creator.

#### Experience Limits

Each experience is allowed a certain number of data store requests based on the data store type, request type, and number of concurrent users. For each data store type and request type, the limit is shared among all listed functions.

Note that `Class.GlobalDataStore:UpdateAsync()|UpdateAsync()` consumes from both the read and write request budgets. A single call will decrement both limits.

##### Standard data stores

| Request type | Functions | Requests per minute |
| --- | --- | --- |
| **Read** | `Class.DataStore:GetAsync()\|GetAsync()`<br>`Class.DataStore:GetVersionAsync()\|GetVersionAsync()`<br>`Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()`<br>`Class.DataStore:UpdateAsync()\|UpdateAsync()` | 250 + concurrentUsers × 40 |
| **Write** | `Class.DataStore:SetAsync()\|SetAsync()`<br>`Class.DataStore:IncrementAsync()\|IncrementAsync()`<br>`Class.DataStore:UpdateAsync()\|UpdateAsync()` | 250 + concurrentUsers × 20 |
| **List** | `Class.DataStoreService:ListDataStoresAsync()\|ListDataStoresAsync()`<br>`Class.DataStore:ListKeysAsync()\|ListKeysAsync()`<br>`Class.DataStore:ListVersionsAsync()\|ListVersionsAsync()` | 10 + concurrentUsers × 2 |
| **Remove** | `Class.DataStore:RemoveAsync()\|RemoveAsync()` | 100 + concurrentUsers × 40 |

##### Ordered data stores

| Request type | Functions | Requests per minute |
| --- | --- | --- |
| **Read** | `Class.OrderedDataStore:GetAsync()\|GetAsync()`<br>`Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` | 250 + concurrentUsers × 40 |
| **Write** | `Class.OrderedDataStore:SetAsync()\|SetAsync()`<br>`Class.OrderedDataStore:IncrementAsync()\|IncrementAsync()`<br>`Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` | 250 + concurrentUsers × 20 |
| **List** | `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` | 100 + concurrentUsers × 2 |
| **Remove** | `Class.OrderedDataStore:RemoveAsync()\|RemoveAsync()` | 100 + concurrentUsers × 40 |

#### Server limits

Each server has a configurable rate limit for each request type, based on the number of players in that server. Servers receive a one-time startup burst of additional request budget when they are first created. Use `Class.DataStoreService:GetRequestBudgetForRequestType()|GetRequestBudgetForRequestType()` to confirm the number of data store requests that the current server can make at any given time.

These limits are **configurable by the creator** using the `Class.DataStoreService:SetRateLimitForRequestType()|SetRateLimitForRequestType()` API. Using this API, a creator can configure their own data stores rate limits for each request type.

The following **default rate limits** apply if the API is not called:

##### Standard data stores

| Request type | `DataStoreRequestType` Enum | Functions | Requests per minute |
| --- | --- | --- | --- |
| **Read** | `StandardRead` | `Class.DataStore:GetAsync()\|GetAsync()`<br>`Class.DataStore:GetVersionAsync()\|GetVersionAsync()`<br>`Class.DataStore:GetVersionAtTimeAsync()\|GetVersionAtTimeAsync()`<br>`Class.DataStore:UpdateAsync()\|UpdateAsync()` | 60 + numPlayers × 40 |
| **Write** | `StandardWrite` | `Class.DataStore:SetAsync()\|SetAsync()`<br>`Class.DataStore:IncrementAsync()\|IncrementAsync()`<br>`Class.DataStore:UpdateAsync()\|UpdateAsync()` | 60 + numPlayers × 40 |
| **List** | `StandardList` | `Class.DataStoreService:ListDataStoresAsync()\|ListDataStoresAsync()`<br>`Class.DataStore:ListKeysAsync()\|ListKeysAsync()`<br>`Class.DataStore:ListVersionsAsync()\|ListVersionsAsync()` | 5 + numPlayers × 2 |
| **Remove** | `StandardRemove` | `Class.DataStore:RemoveAsync()\|RemoveAsync()` | 60 + numPlayers × 40 |
| **RemoveVersion (Deprecated)** | `RemoveVersionAsync` | `Class.DataStore:RemoveVersionAsync()\|RemoveVersionAsync()` | 5 + numPlayers × 2 |

##### Ordered data stores

| Request type | `DataStoreRequestType` Enum | Functions | Requests per minute |
| --- | --- | --- | --- |
| **Read** | `OrderedRead` | `Class.OrderedDataStore:GetAsync()\|GetAsync()`<br>`Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` | 60 + numPlayers × 40 |
| **Write** | `OrderedWrite` | `Class.OrderedDataStore:SetAsync()\|SetAsync()`<br>`Class.OrderedDataStore:IncrementAsync()\|IncrementAsync()`<br>`Class.OrderedDataStore:UpdateAsync()\|UpdateAsync()` | 30 + numPlayers × 5 |
| **List** | `OrderedList` | `Class.OrderedDataStore:GetSortedAsync()\|GetSortedAsync()` | 5 + numPlayers × 2 |
| **Remove** | `OrderedRemove` | `Class.OrderedDataStore:RemoveAsync()\|RemoveAsync()` | 30 + numPlayers × 5 |

> **Info:** Data store requests made in Studio Run mode are subject to a separate set of static limits, which may be lower than the limits configured with `Class.DataStoreService:SetRateLimitForRequestType()|SetRateLimitForRequestType()`. When testing rate limits, we recommend using Studio Team Create instead.
### Data limits

Data stores limit how much data can be used per entry.

The data store name, key name, and [scope](/docs/en-us/cloud-services/data-stores/versioning-listing-and-caching.md#scopes) must all be under a certain character length. Use `Library.string.len()` to check their length.

The data (key value) is also stored as a string, regardless of its initial type. You can check the size of the data with the `Class.HttpService:JSONEncode()|JSONEncode()` function, which converts Luau data into a serialized JSON table.

| Component | Maximum number of characters |
| --- | --- |
| Data store name | 50 |
| Key name | 50 |
| Scope | 50 |
| Data (key value) | 4,194,304 per key |

### Metadata limits

Limits to the number of characters in user-defined metadata.

| Component | Maximum number of characters |
| --- | --- |
| Key name | 50 |
| Value | 250 |
| Key-value pairs | 300 |

> **Info:** There's no limit to the total number of key-value pairs, but the total size can't exceed 300 characters.
### Throughput limits

Per-key throughput limits ensure that performance is optimal on Roblox servers. Each limit applies to every single key across all servers in an experience and refreshes over time.

Roblox examines the usage of quota associated with the key over the last 60 seconds. If the usage, including the current request, is within the throughput limit, the request is approved. If the usage exceeds the limit, the request is denied.

| Request type | Limit |
| --- | --- |
| Read | 25 MB per minute |
| Write | 4 MB per minute |

In addition to the above throughput limits, Roblox organizes data into partitions based on an internal schema. As a result, when the backend server receives a high volume of requests to the same data store, it can result in further throttling. Regardless of the cause, throttling manifests as either `DatastoreThrottled` or `KeyThrottled` errors, depending on whether the throughput limit was exceeded for a single data store or a key. These error messages apply to both ordered and standard data stores.

> **Info:** For every request, Roblox rounds throughput up to the next kilobyte. For example, if you write 800 bytes and 1.2 KB in two requests, Roblox counts that as 3 KB total throughput (1 KB and 2 KB, respectively).
### Storage limits

In the future, to provide a scalable and stable storage experience, data stores will implement an experience-level storage limit on your storage usage.

This limit will be the sum of a base limit for each of your experiences and a per-user limit based on the number of lifetime users in your experience. A lifetime user is any user who has joined your experience at least once.

The storage limit will be calculated using the formula `Total latest version storage limit = 100 MB + 1 MB * lifetime user count`.

Any keys that you delete or replace, even if still accessible through version APIs, do not count towards your experience's storage usage. However, entire data stores deleted via the Open Cloud [`DeleteDataStore`](/docs/en-us/cloud/reference/DataStore.md#Cloud_DeleteDataStore) method continue to count towards your storage usage for the duration of their 30-day processing period, until they are permanently deleted.