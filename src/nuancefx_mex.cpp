/* temp.cpp
 *
 *  Created on: May 22, 2012
 *      Author: igkiou
 */

#include "nuancefx_mex.h"

namespace nuance {

void setCameraProperty(const cri_CameraHandle handle, \
							const char* propertyName, \
							const mxArray* mxarr) {

	cri_ErrorCode errorCode;
	double val = mxGetScalar(mxarr);
	if(!strcasecmp(propertyName, "bitdepth")) {
		errorCode = cri_SetCameraBitDepth(handle, (cri_ECameraBitDepth) val);
	} else if(!strcasecmp(propertyName, "gain")) {
		errorCode = cri_SetCameraGain(handle, (cri_ECameraGain) val);
	} else if(!strcasecmp(propertyName, "exposure")) {
		errorCode = cri_SetCameraExposureMs(handle, (float) val);
	} else if(!strcasecmp(propertyName, "binning")) {
		errorCode = cri_SetCameraBinning(handle, (cri_ECameraBinning) val);
	} else if(!strcasecmp(propertyName, "offset")) {
		errorCode = cri_SetCameraOffset(handle, (int) val);
	} else {
		mexErrMsgTxt("Unknown or unsupported camera property.");
	}
	if (errorCode != cri_NoError) {
		handleErrorCode(errorCode);
	}
}

void getCameraProperty(const cri_CameraHandle handle, \
							const char* propertyName, \
							mxArray* mxarr) {

	cri_ErrorCode errorCode;
	if (!strcasecmp(propertyName, "name")) {
		char name[cri_MAX_STRING_LENGTH];
		char serial[cri_MAX_STRING_LENGTH];
		char sensor[cri_MAX_STRING_LENGTH];
		cri_ECameraBitDepth maxBitDepth;
		int sensorWidth;
		int sensorHeight;
		char driver[cri_MAX_STRING_LENGTH];
		char firmware[cri_MAX_STRING_LENGTH];
		errorCode = cri_GetCameraDescription(handle, name, serial, sensor, \
										&maxBitDepth, &sensorWidth, &sensorHeight, \
										driver, firmware);
		mxarr = mxCreateString(name);
	} else if (!strcasecmp(propertyName, "serial")) {
		char name[cri_MAX_STRING_LENGTH];
		char serial[cri_MAX_STRING_LENGTH];
		char sensor[cri_MAX_STRING_LENGTH];
		cri_ECameraBitDepth maxBitDepth;
		int sensorWidth;
		int sensorHeight;
		char driver[cri_MAX_STRING_LENGTH];
		char firmware[cri_MAX_STRING_LENGTH];
		errorCode = cri_GetCameraDescription(handle, name, serial, sensor, \
										&maxBitDepth, &sensorWidth, &sensorHeight, \
										driver, firmware);
		mxarr = mxCreateString(serial);
	} else if (!strcasecmp(propertyName, "driver")) {
		char name[cri_MAX_STRING_LENGTH];
		char serial[cri_MAX_STRING_LENGTH];
		char sensor[cri_MAX_STRING_LENGTH];
		cri_ECameraBitDepth maxBitDepth;
		int sensorWidth;
		int sensorHeight;
		char driver[cri_MAX_STRING_LENGTH];
		char firmware[cri_MAX_STRING_LENGTH];
		errorCode = cri_GetCameraDescription(handle, name, serial, sensor, \
										&maxBitDepth, &sensorWidth, &sensorHeight, \
										driver, firmware);
		mxarr = mxCreateString(driver);
	} else if (!strcasecmp(propertyName, "firmware")) {
		char name[cri_MAX_STRING_LENGTH];
		char serial[cri_MAX_STRING_LENGTH];
		char sensor[cri_MAX_STRING_LENGTH];
		cri_ECameraBitDepth maxBitDepth;
		int sensorWidth;
		int sensorHeight;
		char driver[cri_MAX_STRING_LENGTH];
		char firmware[cri_MAX_STRING_LENGTH];
		errorCode = cri_GetCameraDescription(handle, name, serial, sensor, \
										&maxBitDepth, &sensorWidth, &sensorHeight, \
										driver, firmware);
		mxarr = mxCreateString(firmware);
	} else if (!strcasecmp(propertyName, "sensor")) {
		char name[cri_MAX_STRING_LENGTH];
		char serial[cri_MAX_STRING_LENGTH];
		char sensor[cri_MAX_STRING_LENGTH];
		cri_ECameraBitDepth maxBitDepth;
		int sensorWidth;
		int sensorHeight;
		char driver[cri_MAX_STRING_LENGTH];
		char firmware[cri_MAX_STRING_LENGTH];
		errorCode = cri_GetCameraDescription(handle, name, serial, sensor, \
										&maxBitDepth, &sensorWidth, &sensorHeight, \
										driver, firmware);
		mxarr = mxCreateString(sensor);
	} else if (!strcasecmp(propertyName, "sensorsize")) {
		int width;
		int height;
		errorCode = cri_GetCameraSensorSize(handle, &width, &height);
		mxarr = mxCreateDoubleMatrix(2, 1, mxREAL);
		double *data = (double *) mxGetData(mxarr);
		data[0] = (double) width;
		data[1] = (double) height;
	} else if (!strcasecmp(propertyName, "imagesize")) {
		int width;
		int height;
		errorCode = cri_GetCameraImageSize(handle, &width, &height);
		mxarr = mxCreateDoubleMatrix(2, 1, mxREAL);
		double *data = (double *) mxGetData(mxarr);
		data[0] = (double) width;
		data[1] = (double) height;
	} else if (!strcasecmp(propertyName, "maxbitdepth")) {
		char name[cri_MAX_STRING_LENGTH];
		char serial[cri_MAX_STRING_LENGTH];
		char sensor[cri_MAX_STRING_LENGTH];
		cri_ECameraBitDepth maxBitDepth;
		int sensorWidth;
		int sensorHeight;
		char driver[cri_MAX_STRING_LENGTH];
		char firmware[cri_MAX_STRING_LENGTH];
		errorCode = cri_GetCameraDescription(handle, name, serial, sensor, \
										&maxBitDepth, &sensorWidth, &sensorHeight, \
										driver, firmware);
		mxarr = mxCreateDoubleScalar((double) maxBitDepth);
	} else if(!strcasecmp(propertyName, "bitdepth")) {
		cri_ECameraBitDepth bitDepth;
		errorCode = cri_GetCameraBitDepth(handle, &bitDepth);
		mxarr = mxCreateDoubleScalar((double) bitDepth);
	} else if(!strcasecmp(propertyName, "gainrange")) {
		int lowRange;
		int highRange;
		errorCode = cri_GetCameraGainRange(handle, &lowRange, &highRange);
		mxarr = mxCreateDoubleMatrix(2, 1, mxREAL);
		double *data = (double *) mxGetData(mxarr);
		data[0] = (double) lowRange;
		data[1] = (double) highRange;
	} else if(!strcasecmp(propertyName, "gain")) {
		cri_ECameraGain gain;
		errorCode = cri_GetCameraGain(handle, &gain);
		mxarr = mxCreateDoubleScalar((double) gain);
	} else if(!strcasecmp(propertyName, "exposurerange")) {
		float lowRange;
		float highRange;
		errorCode = cri_GetCameraExposureRangeMs(handle, &lowRange, &highRange);
		mxarr = mxCreateDoubleMatrix(2, 1, mxREAL);
		double *data = (double *) mxGetData(mxarr);
		data[0] = (double) lowRange;
		data[1] = (double) highRange;
	} else if(!strcasecmp(propertyName, "exposure")) {
		float exposure;
		errorCode = cri_GetCameraExposureMs(handle, &exposure);
		mxarr = mxCreateDoubleScalar((double) exposure);
	} else if(!strcasecmp(propertyName, "binning")) {
		cri_ECameraBinning binning;
		errorCode = cri_GetCameraBinning(handle, &binning);
		mxarr = mxCreateDoubleScalar((double) binning);
	} else if(!strcasecmp(propertyName, "offsetrange")) {
		int lowRange;
		int highRange;
		errorCode = cri_GetCameraOffsetRange(handle, &lowRange, &highRange);
		mxarr = mxCreateDoubleMatrix(2, 1, mxREAL);
		double *data = (double *) mxGetData(mxarr);
		data[0] = (double) lowRange;
		data[1] = (double) highRange;
	} else if(!strcasecmp(propertyName, "offset")) {
		int offset;
		errorCode = cri_GetCameraOffset(handle, &offset);
		mxarr = mxCreateDoubleScalar((double) offset);
	} else {
		mexErrMsgTxt("Unknown or unsupported camera property.");
	}
	if (errorCode != cri_NoError) {
		handleErrorCode(errorCode);
	}
}

void getCameraProperties(const cri_CameraHandle handle, mxArray* mxstruct) {

	char **propertyNames = (char **) \
			mxMalloc((size_t) CAMERA_PROPERTY_LENGTH * sizeof(*propertyNames));
	for (CAMERA_PROPERTY iterProperty = 0; iterProperty < CAMERA_PROPERTY_LENGTH; ++iterProperty) {
		propertyNames[iterProperty] = (char *) mxMalloc(cri_MAX_STRING_LENGTH * sizeof(char));
		cameraPropertyToString(iterProperty, propertyNames[iterProperty]);
	}
	mxstruct = mxCreateStructMatrix(1, 1, (int) CAMERA_PROPERTY_LENGTH, (const char **) propertyNames);
	mxArray *temp;
	for (CAMERA_PROPERTY iterProperty = 0; iterProperty < CAMERA_PROPERTY_LENGTH; ++iterProperty) {
		getCameraProperty(handle, propertyNames[iterProperty], temp);
		mxSetFieldByNumber(mxstruct, 0, iterProperty, temp);
	}
	for (CAMERA_PROPERTY iterProperty = 0; iterProperty < CAMERA_PROPERTY_LENGTH; ++iterProperty) {
		mxFree((void *) propertyNames[iterProperty]);
	}
	mxFree((void *) propertyNames);
}


void setCameraProperties(const cri_CameraHandle handle, const mxArray* mxstruct) {

	if (mxIsStruct(mxstruct)) {
		int numProperties = mxGetNumberOfFields(mxstruct);
		for (int iterProperty = 0; iterProperty < numProperties; ++iterProperty) {
			setCameraProperty(handle, mxGetFieldNameByNumber(mxstruct, iterProperty), \
							mxGetFieldByNumber(mxstruct, 0, iterProperty));
		}
	} else if (!mxIsEmpty(mxstruct)) {
		mexErrMsgTxt("For setting multiple attributes, a struct array must be provided.");
	}
}



}	/* namespace nuance */
