/*
Daytona

Daytona AI platform API Docs

API version: 1.0
Contact: support@daytona.com
*/

// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

package apiclient

import (
	"bytes"
	"encoding/json"
	"fmt"
	"time"
)

// checks if the AuditLog type satisfies the MappedNullable interface at compile time
var _ MappedNullable = &AuditLog{}

// AuditLog struct for AuditLog
type AuditLog struct {
	Id             string                 `json:"id"`
	ActorId        string                 `json:"actorId"`
	ActorEmail     string                 `json:"actorEmail"`
	OrganizationId *string                `json:"organizationId,omitempty"`
	Action         string                 `json:"action"`
	TargetType     *string                `json:"targetType,omitempty"`
	TargetId       *string                `json:"targetId,omitempty"`
	StatusCode     *float32               `json:"statusCode,omitempty"`
	ErrorMessage   *string                `json:"errorMessage,omitempty"`
	IpAddress      *string                `json:"ipAddress,omitempty"`
	UserAgent      *string                `json:"userAgent,omitempty"`
	Source         *string                `json:"source,omitempty"`
	Metadata       map[string]interface{} `json:"metadata,omitempty"`
	CreatedAt      time.Time              `json:"createdAt"`
}

type _AuditLog AuditLog

// NewAuditLog instantiates a new AuditLog object
// This constructor will assign default values to properties that have it defined,
// and makes sure properties required by API are set, but the set of arguments
// will change when the set of required properties is changed
func NewAuditLog(id string, actorId string, actorEmail string, action string, createdAt time.Time) *AuditLog {
	this := AuditLog{}
	this.Id = id
	this.ActorId = actorId
	this.ActorEmail = actorEmail
	this.Action = action
	this.CreatedAt = createdAt
	return &this
}

// NewAuditLogWithDefaults instantiates a new AuditLog object
// This constructor will only assign default values to properties that have it defined,
// but it doesn't guarantee that properties required by API are set
func NewAuditLogWithDefaults() *AuditLog {
	this := AuditLog{}
	return &this
}

// GetId returns the Id field value
func (o *AuditLog) GetId() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.Id
}

// GetIdOk returns a tuple with the Id field value
// and a boolean to check if the value has been set.
func (o *AuditLog) GetIdOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.Id, true
}

// SetId sets field value
func (o *AuditLog) SetId(v string) {
	o.Id = v
}

// GetActorId returns the ActorId field value
func (o *AuditLog) GetActorId() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.ActorId
}

// GetActorIdOk returns a tuple with the ActorId field value
// and a boolean to check if the value has been set.
func (o *AuditLog) GetActorIdOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.ActorId, true
}

// SetActorId sets field value
func (o *AuditLog) SetActorId(v string) {
	o.ActorId = v
}

// GetActorEmail returns the ActorEmail field value
func (o *AuditLog) GetActorEmail() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.ActorEmail
}

// GetActorEmailOk returns a tuple with the ActorEmail field value
// and a boolean to check if the value has been set.
func (o *AuditLog) GetActorEmailOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.ActorEmail, true
}

// SetActorEmail sets field value
func (o *AuditLog) SetActorEmail(v string) {
	o.ActorEmail = v
}

// GetOrganizationId returns the OrganizationId field value if set, zero value otherwise.
func (o *AuditLog) GetOrganizationId() string {
	if o == nil || IsNil(o.OrganizationId) {
		var ret string
		return ret
	}
	return *o.OrganizationId
}

// GetOrganizationIdOk returns a tuple with the OrganizationId field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetOrganizationIdOk() (*string, bool) {
	if o == nil || IsNil(o.OrganizationId) {
		return nil, false
	}
	return o.OrganizationId, true
}

// HasOrganizationId returns a boolean if a field has been set.
func (o *AuditLog) HasOrganizationId() bool {
	if o != nil && !IsNil(o.OrganizationId) {
		return true
	}

	return false
}

// SetOrganizationId gets a reference to the given string and assigns it to the OrganizationId field.
func (o *AuditLog) SetOrganizationId(v string) {
	o.OrganizationId = &v
}

// GetAction returns the Action field value
func (o *AuditLog) GetAction() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.Action
}

// GetActionOk returns a tuple with the Action field value
// and a boolean to check if the value has been set.
func (o *AuditLog) GetActionOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.Action, true
}

// SetAction sets field value
func (o *AuditLog) SetAction(v string) {
	o.Action = v
}

// GetTargetType returns the TargetType field value if set, zero value otherwise.
func (o *AuditLog) GetTargetType() string {
	if o == nil || IsNil(o.TargetType) {
		var ret string
		return ret
	}
	return *o.TargetType
}

// GetTargetTypeOk returns a tuple with the TargetType field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetTargetTypeOk() (*string, bool) {
	if o == nil || IsNil(o.TargetType) {
		return nil, false
	}
	return o.TargetType, true
}

// HasTargetType returns a boolean if a field has been set.
func (o *AuditLog) HasTargetType() bool {
	if o != nil && !IsNil(o.TargetType) {
		return true
	}

	return false
}

// SetTargetType gets a reference to the given string and assigns it to the TargetType field.
func (o *AuditLog) SetTargetType(v string) {
	o.TargetType = &v
}

// GetTargetId returns the TargetId field value if set, zero value otherwise.
func (o *AuditLog) GetTargetId() string {
	if o == nil || IsNil(o.TargetId) {
		var ret string
		return ret
	}
	return *o.TargetId
}

// GetTargetIdOk returns a tuple with the TargetId field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetTargetIdOk() (*string, bool) {
	if o == nil || IsNil(o.TargetId) {
		return nil, false
	}
	return o.TargetId, true
}

// HasTargetId returns a boolean if a field has been set.
func (o *AuditLog) HasTargetId() bool {
	if o != nil && !IsNil(o.TargetId) {
		return true
	}

	return false
}

// SetTargetId gets a reference to the given string and assigns it to the TargetId field.
func (o *AuditLog) SetTargetId(v string) {
	o.TargetId = &v
}

// GetStatusCode returns the StatusCode field value if set, zero value otherwise.
func (o *AuditLog) GetStatusCode() float32 {
	if o == nil || IsNil(o.StatusCode) {
		var ret float32
		return ret
	}
	return *o.StatusCode
}

// GetStatusCodeOk returns a tuple with the StatusCode field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetStatusCodeOk() (*float32, bool) {
	if o == nil || IsNil(o.StatusCode) {
		return nil, false
	}
	return o.StatusCode, true
}

// HasStatusCode returns a boolean if a field has been set.
func (o *AuditLog) HasStatusCode() bool {
	if o != nil && !IsNil(o.StatusCode) {
		return true
	}

	return false
}

// SetStatusCode gets a reference to the given float32 and assigns it to the StatusCode field.
func (o *AuditLog) SetStatusCode(v float32) {
	o.StatusCode = &v
}

// GetErrorMessage returns the ErrorMessage field value if set, zero value otherwise.
func (o *AuditLog) GetErrorMessage() string {
	if o == nil || IsNil(o.ErrorMessage) {
		var ret string
		return ret
	}
	return *o.ErrorMessage
}

// GetErrorMessageOk returns a tuple with the ErrorMessage field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetErrorMessageOk() (*string, bool) {
	if o == nil || IsNil(o.ErrorMessage) {
		return nil, false
	}
	return o.ErrorMessage, true
}

// HasErrorMessage returns a boolean if a field has been set.
func (o *AuditLog) HasErrorMessage() bool {
	if o != nil && !IsNil(o.ErrorMessage) {
		return true
	}

	return false
}

// SetErrorMessage gets a reference to the given string and assigns it to the ErrorMessage field.
func (o *AuditLog) SetErrorMessage(v string) {
	o.ErrorMessage = &v
}

// GetIpAddress returns the IpAddress field value if set, zero value otherwise.
func (o *AuditLog) GetIpAddress() string {
	if o == nil || IsNil(o.IpAddress) {
		var ret string
		return ret
	}
	return *o.IpAddress
}

// GetIpAddressOk returns a tuple with the IpAddress field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetIpAddressOk() (*string, bool) {
	if o == nil || IsNil(o.IpAddress) {
		return nil, false
	}
	return o.IpAddress, true
}

// HasIpAddress returns a boolean if a field has been set.
func (o *AuditLog) HasIpAddress() bool {
	if o != nil && !IsNil(o.IpAddress) {
		return true
	}

	return false
}

// SetIpAddress gets a reference to the given string and assigns it to the IpAddress field.
func (o *AuditLog) SetIpAddress(v string) {
	o.IpAddress = &v
}

// GetUserAgent returns the UserAgent field value if set, zero value otherwise.
func (o *AuditLog) GetUserAgent() string {
	if o == nil || IsNil(o.UserAgent) {
		var ret string
		return ret
	}
	return *o.UserAgent
}

// GetUserAgentOk returns a tuple with the UserAgent field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetUserAgentOk() (*string, bool) {
	if o == nil || IsNil(o.UserAgent) {
		return nil, false
	}
	return o.UserAgent, true
}

// HasUserAgent returns a boolean if a field has been set.
func (o *AuditLog) HasUserAgent() bool {
	if o != nil && !IsNil(o.UserAgent) {
		return true
	}

	return false
}

// SetUserAgent gets a reference to the given string and assigns it to the UserAgent field.
func (o *AuditLog) SetUserAgent(v string) {
	o.UserAgent = &v
}

// GetSource returns the Source field value if set, zero value otherwise.
func (o *AuditLog) GetSource() string {
	if o == nil || IsNil(o.Source) {
		var ret string
		return ret
	}
	return *o.Source
}

// GetSourceOk returns a tuple with the Source field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetSourceOk() (*string, bool) {
	if o == nil || IsNil(o.Source) {
		return nil, false
	}
	return o.Source, true
}

// HasSource returns a boolean if a field has been set.
func (o *AuditLog) HasSource() bool {
	if o != nil && !IsNil(o.Source) {
		return true
	}

	return false
}

// SetSource gets a reference to the given string and assigns it to the Source field.
func (o *AuditLog) SetSource(v string) {
	o.Source = &v
}

// GetMetadata returns the Metadata field value if set, zero value otherwise.
func (o *AuditLog) GetMetadata() map[string]interface{} {
	if o == nil || IsNil(o.Metadata) {
		var ret map[string]interface{}
		return ret
	}
	return o.Metadata
}

// GetMetadataOk returns a tuple with the Metadata field value if set, nil otherwise
// and a boolean to check if the value has been set.
func (o *AuditLog) GetMetadataOk() (map[string]interface{}, bool) {
	if o == nil || IsNil(o.Metadata) {
		return map[string]interface{}{}, false
	}
	return o.Metadata, true
}

// HasMetadata returns a boolean if a field has been set.
func (o *AuditLog) HasMetadata() bool {
	if o != nil && !IsNil(o.Metadata) {
		return true
	}

	return false
}

// SetMetadata gets a reference to the given map[string]interface{} and assigns it to the Metadata field.
func (o *AuditLog) SetMetadata(v map[string]interface{}) {
	o.Metadata = v
}

// GetCreatedAt returns the CreatedAt field value
func (o *AuditLog) GetCreatedAt() time.Time {
	if o == nil {
		var ret time.Time
		return ret
	}

	return o.CreatedAt
}

// GetCreatedAtOk returns a tuple with the CreatedAt field value
// and a boolean to check if the value has been set.
func (o *AuditLog) GetCreatedAtOk() (*time.Time, bool) {
	if o == nil {
		return nil, false
	}
	return &o.CreatedAt, true
}

// SetCreatedAt sets field value
func (o *AuditLog) SetCreatedAt(v time.Time) {
	o.CreatedAt = v
}

func (o AuditLog) MarshalJSON() ([]byte, error) {
	toSerialize, err := o.ToMap()
	if err != nil {
		return []byte{}, err
	}
	return json.Marshal(toSerialize)
}

func (o AuditLog) ToMap() (map[string]interface{}, error) {
	toSerialize := map[string]interface{}{}
	toSerialize["id"] = o.Id
	toSerialize["actorId"] = o.ActorId
	toSerialize["actorEmail"] = o.ActorEmail
	if !IsNil(o.OrganizationId) {
		toSerialize["organizationId"] = o.OrganizationId
	}
	toSerialize["action"] = o.Action
	if !IsNil(o.TargetType) {
		toSerialize["targetType"] = o.TargetType
	}
	if !IsNil(o.TargetId) {
		toSerialize["targetId"] = o.TargetId
	}
	if !IsNil(o.StatusCode) {
		toSerialize["statusCode"] = o.StatusCode
	}
	if !IsNil(o.ErrorMessage) {
		toSerialize["errorMessage"] = o.ErrorMessage
	}
	if !IsNil(o.IpAddress) {
		toSerialize["ipAddress"] = o.IpAddress
	}
	if !IsNil(o.UserAgent) {
		toSerialize["userAgent"] = o.UserAgent
	}
	if !IsNil(o.Source) {
		toSerialize["source"] = o.Source
	}
	if !IsNil(o.Metadata) {
		toSerialize["metadata"] = o.Metadata
	}
	toSerialize["createdAt"] = o.CreatedAt
	return toSerialize, nil
}

func (o *AuditLog) UnmarshalJSON(data []byte) (err error) {
	// This validates that all required properties are included in the JSON object
	// by unmarshalling the object into a generic map with string keys and checking
	// that every required field exists as a key in the generic map.
	requiredProperties := []string{
		"id",
		"actorId",
		"actorEmail",
		"action",
		"createdAt",
	}

	allProperties := make(map[string]interface{})

	err = json.Unmarshal(data, &allProperties)

	if err != nil {
		return err
	}

	for _, requiredProperty := range requiredProperties {
		if _, exists := allProperties[requiredProperty]; !exists {
			return fmt.Errorf("no value given for required property %v", requiredProperty)
		}
	}

	varAuditLog := _AuditLog{}

	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	err = decoder.Decode(&varAuditLog)

	if err != nil {
		return err
	}

	*o = AuditLog(varAuditLog)

	return err
}

type NullableAuditLog struct {
	value *AuditLog
	isSet bool
}

func (v NullableAuditLog) Get() *AuditLog {
	return v.value
}

func (v *NullableAuditLog) Set(val *AuditLog) {
	v.value = val
	v.isSet = true
}

func (v NullableAuditLog) IsSet() bool {
	return v.isSet
}

func (v *NullableAuditLog) Unset() {
	v.value = nil
	v.isSet = false
}

func NewNullableAuditLog(val *AuditLog) *NullableAuditLog {
	return &NullableAuditLog{value: val, isSet: true}
}

func (v NullableAuditLog) MarshalJSON() ([]byte, error) {
	return json.Marshal(v.value)
}

func (v *NullableAuditLog) UnmarshalJSON(src []byte) error {
	v.isSet = true
	return json.Unmarshal(src, &v.value)
}
