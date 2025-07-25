/*
Daytona

Daytona AI platform API Docs

API version: 1.0
Contact: support@daytona.com
*/

// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

package daytonaapiclient

import (
	"bytes"
	"encoding/json"
	"fmt"
)

// checks if the SandboxVolume type satisfies the MappedNullable interface at compile time
var _ MappedNullable = &SandboxVolume{}

// SandboxVolume struct for SandboxVolume
type SandboxVolume struct {
	// The ID of the volume
	VolumeId string `json:"volumeId"`
	// The mount path for the volume
	MountPath string `json:"mountPath"`
}

type _SandboxVolume SandboxVolume

// NewSandboxVolume instantiates a new SandboxVolume object
// This constructor will assign default values to properties that have it defined,
// and makes sure properties required by API are set, but the set of arguments
// will change when the set of required properties is changed
func NewSandboxVolume(volumeId string, mountPath string) *SandboxVolume {
	this := SandboxVolume{}
	this.VolumeId = volumeId
	this.MountPath = mountPath
	return &this
}

// NewSandboxVolumeWithDefaults instantiates a new SandboxVolume object
// This constructor will only assign default values to properties that have it defined,
// but it doesn't guarantee that properties required by API are set
func NewSandboxVolumeWithDefaults() *SandboxVolume {
	this := SandboxVolume{}
	return &this
}

// GetVolumeId returns the VolumeId field value
func (o *SandboxVolume) GetVolumeId() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.VolumeId
}

// GetVolumeIdOk returns a tuple with the VolumeId field value
// and a boolean to check if the value has been set.
func (o *SandboxVolume) GetVolumeIdOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.VolumeId, true
}

// SetVolumeId sets field value
func (o *SandboxVolume) SetVolumeId(v string) {
	o.VolumeId = v
}

// GetMountPath returns the MountPath field value
func (o *SandboxVolume) GetMountPath() string {
	if o == nil {
		var ret string
		return ret
	}

	return o.MountPath
}

// GetMountPathOk returns a tuple with the MountPath field value
// and a boolean to check if the value has been set.
func (o *SandboxVolume) GetMountPathOk() (*string, bool) {
	if o == nil {
		return nil, false
	}
	return &o.MountPath, true
}

// SetMountPath sets field value
func (o *SandboxVolume) SetMountPath(v string) {
	o.MountPath = v
}

func (o SandboxVolume) MarshalJSON() ([]byte, error) {
	toSerialize, err := o.ToMap()
	if err != nil {
		return []byte{}, err
	}
	return json.Marshal(toSerialize)
}

func (o SandboxVolume) ToMap() (map[string]interface{}, error) {
	toSerialize := map[string]interface{}{}
	toSerialize["volumeId"] = o.VolumeId
	toSerialize["mountPath"] = o.MountPath
	return toSerialize, nil
}

func (o *SandboxVolume) UnmarshalJSON(data []byte) (err error) {
	// This validates that all required properties are included in the JSON object
	// by unmarshalling the object into a generic map with string keys and checking
	// that every required field exists as a key in the generic map.
	requiredProperties := []string{
		"volumeId",
		"mountPath",
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

	varSandboxVolume := _SandboxVolume{}

	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	err = decoder.Decode(&varSandboxVolume)

	if err != nil {
		return err
	}

	*o = SandboxVolume(varSandboxVolume)

	return err
}

type NullableSandboxVolume struct {
	value *SandboxVolume
	isSet bool
}

func (v NullableSandboxVolume) Get() *SandboxVolume {
	return v.value
}

func (v *NullableSandboxVolume) Set(val *SandboxVolume) {
	v.value = val
	v.isSet = true
}

func (v NullableSandboxVolume) IsSet() bool {
	return v.isSet
}

func (v *NullableSandboxVolume) Unset() {
	v.value = nil
	v.isSet = false
}

func NewNullableSandboxVolume(val *SandboxVolume) *NullableSandboxVolume {
	return &NullableSandboxVolume{value: val, isSet: true}
}

func (v NullableSandboxVolume) MarshalJSON() ([]byte, error) {
	return json.Marshal(v.value)
}

func (v *NullableSandboxVolume) UnmarshalJSON(src []byte) error {
	v.isSet = true
	return json.Unmarshal(src, &v.value)
}
