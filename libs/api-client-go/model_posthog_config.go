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
)

// checks if the PosthogConfig type satisfies the MappedNullable interface at compile time
var _ MappedNullable = &PosthogConfig{}

// PosthogConfig struct for PosthogConfig
type PosthogConfig struct {
	// PostHog API key
	ApiKey string `json:"apiKey"`
	// PostHog host URL
	Host string `json:"host"`
}

type _PosthogConfig PosthogConfig

// NewPosthogConfig instantiates a new PosthogConfig object
// This constructor will assign default values to properties that have it defined,
// and makes sure properties required by API are set, but the set of arguments
// will change when the set of required properties is changed
func NewPosthogConfig(apiKey string, host string) *PosthogConfig {
	this := PosthogConfig{}
	this.ApiKey = apiKey
	this.Host = host
	return &this
}

// NewPosthogConfigWithDefaults instantiates a new PosthogConfig object
// This constructor will only assign default values to properties that have it defined,
// but it doesn't guarantee that properties required by API are set
func NewPosthogConfigWithDefaults() *PosthogConfig {
	this := PosthogConfig{}
	return &this
}

// GetApiKey returns the ApiKey field value
func (o *PosthogConfig) GetApiKey() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.ApiKey
}

// GetApiKeyOk returns a tuple with the ApiKey field value
// and a boolean to check if the value has been set.
func (o *PosthogConfig) GetApiKeyOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.ApiKey, true
}

// SetApiKey sets field value
func (o *PosthogConfig) SetApiKey(v string) {
	o.ApiKey = v
}

// GetHost returns the Host field value
func (o *PosthogConfig) GetHost() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.Host
}

// GetHostOk returns a tuple with the Host field value
// and a boolean to check if the value has been set.
func (o *PosthogConfig) GetHostOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.Host, true
}

// SetHost sets field value
func (o *PosthogConfig) SetHost(v string) {
	o.Host = v
}

func (o PosthogConfig) MarshalJSON() ([]byte, error) {
	toSerialize, err := o.ToMap()
	if err != nil {
		return []byte{}, err
	}
	return json.Marshal(toSerialize)
}

func (o PosthogConfig) ToMap() (map[string]interface{}, error) {
	toSerialize := map[string]interface{}{}
	toSerialize["apiKey"] = o.ApiKey
	toSerialize["host"] = o.Host
	return toSerialize, nil
}

func (o *PosthogConfig) UnmarshalJSON(data []byte) (err error) {
	// This validates that all required properties are included in the JSON object
	// by unmarshalling the object into a generic map with string keys and checking
	// that every required field exists as a key in the generic map.
	requiredProperties := []string{
		"apiKey",
		"host",
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

	varPosthogConfig := _PosthogConfig{}

	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	err = decoder.Decode(&varPosthogConfig)

	if err != nil {
		return err
	}

	*o = PosthogConfig(varPosthogConfig)

	return err
}

type NullablePosthogConfig struct {
	value *PosthogConfig
	isSet bool
}

func (v NullablePosthogConfig) Get() *PosthogConfig {
	return v.value
}

func (v *NullablePosthogConfig) Set(val *PosthogConfig) {
	v.value = val
	v.isSet = true
}

func (v NullablePosthogConfig) IsSet() bool {
	return v.isSet
}

func (v *NullablePosthogConfig) Unset() {
	v.value = nil
	v.isSet = false
}

func NewNullablePosthogConfig(val *PosthogConfig) *NullablePosthogConfig {
	return &NullablePosthogConfig{value: val, isSet: true}
}

func (v NullablePosthogConfig) MarshalJSON() ([]byte, error) {
	return json.Marshal(v.value)
}

func (v *NullablePosthogConfig) UnmarshalJSON(src []byte) error {
	v.isSet = true
	return json.Unmarshal(src, &v.value)
}
