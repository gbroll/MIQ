//open("G:\\Röntgen-Isotop\\DICOM Dump\\UFC\\1.2.840.113619.2.253.2.1.2222016153638921.29785_0001_000000_14561544020018.dcm");




var	date 		= "";        				//Image Date
var	dateXlFormat	= "";					//[YYYYMMDD] -> [YY-MM-DD]
				
var	time			= "";		
var	timeXlFormat	= "";					//[hhmmss] -> [hh:mm:ss]

var	stnName		= "";   					//Station Name
var	seriesDesc 	= "";					//Series Description (head1 or head2 for the VG camera)
var	acqTime 		= 0;						//Acquisition Time 
var  totalAcqTime	= 0;						//Total acq time for all source positions
var	eWinLow 		= 0;						//Lower limit Energy Window
var	eWinHigh		= 0;    					//Upper limit Energy Window
var	cllmtr		= ""	       				//Collimator name
var	nCounts 		= 0;						//Number of counts accumulated

var	pixSize     	= 0;						//pixel size
var	mtxSizeX    	= 0;						//number of columns
var	mtxSizeY    	= 0;						//number of rows

var path = "";

var meanArray 		= newArray();
var minArray	 	= newArray();
var maxArray 		= newArray();
var stdArray 		= newArray();
var nImgs 		= 0;							//number of images in the current file
var nDetectors	 	= 0;							//number of detectors in total

var mtxSizeX 		= 0;
var mtxSizeY		= 0;

var acqTimeArr		= newArray();					//acq time for each detector (source position different)
var countArr		= newArray();					//number of counts accumulated for each detector
var IU			= newArray();					//integral uniformity pixel-by-pixel
var IU_GE			= newArray();					//integral uniformity cheating-style a la GE
var nSPix			= newArray();					//number of suspicious pixels per detector
var sPix			= newArray();					//detector-ID:s of suspicious pixels 
var sType			= newArray();					//low (-1) or high (+1) count of the suspicous pixel		
var sPix_x		= newArray();					//x pos of suspicious pixels
var sPix_y 		= newArray();    				//y pos of suspicious pixels

var lowPix         = newArray();					//number of pixels with low count for each detector
var highPix		= newArray();					//number of pixels with high count for each detector

var IU_temp		= 0;							//temporary variables
var IU_GE_temp		= 0;
var nSPix_temp		= 0;
var sPix_temp		= newArray();
var sType_temp		= newArray();
var sPix_x_temp	= newArray();
var sPix_y_temp	= newArray();    

var lowPix_temp	= 0;
var highPix_temp	= 0;

//--------------------------------------------------------------------------------------------------------------------------

var IU_SPS = 2.0;  //Super pixel size as defined by GE for uniformity calculations  (i.e., sum 4 pixels)
var sDevMultiple = 4.0//3.3; //number of standard devaitions from mean to be identified as a suspicious pixel (3.3 about one s pix per detector)
var lLim = 0;
var hLim = 0;

path = getArgument();

//path = "G:\\MF\\Diagnostik\\autoDQA\\NM\\D530_1.2.840.113619.2.253.2.1.1992016144851203.26607\\";

print(path);
fileList = getFiles(path);

if (lengthOf(fileList)!=3){					//there should be 3 files, one for each source position. If not, an error has occured. Exit the macro
	dummy = CloseAllWindows();
	fileRef = File.open(path + "Felmeddelande.txt");
	print(fileRef,"Något gick fel vid analys av bilderna i ImageJ");
	File.close(fileRef);
	run("Quit");
}

dummy = openAndStackImages(fileList);
run("32-bit");

nImgs = nSlices(); 				//get the number of images in the current file

mtxSizeX = getWidth();
mtxSizeY = getHeight();

scale 	= 3;
margin 	= 20;
yOffset 	= 50;	
imgSize  	= 192;
scale = imgSize/mtxSizeX;

IDnumber  = newArray( 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19);  //not used, just to cross-ref positions
positions = newArray( 1, 7, 2, 5, 8,11, 3, 9,13,14,17,15,19,25,20,23,26,21,27);  //position of single detector image


nCols = 9;
nRows = 3;


newImage("Summary", "32-bit black", nCols*(imgSize+margin)+margin,(imgSize+margin)*3+margin+yOffset, 1);

selectImage(1);
rename("Input");



for (i = 0; i<nImgs;i++){
	
	xPos = floor((positions[i]-1)/3);
	yPos = round(((positions[i]-1)/3-xPos)*3); 
	//print(d2s(xPos,0)+","+d2s(yPos,0));

	selectImage(1);
	
	
	setSlice(i+1);
	getRawStatistics(nPixels, mean, min, max, std, histogram);
	nCounts = nPixels*mean;	
	
	stdArray = Array.concat(stdArray,(std/mean));
	minArray = Array.concat(minArray,min);
	maxArray = Array.concat(maxArray,max);


	lLim = maxOf(min,round(mean - sDevMultiple*std));
	hLim = minOf(max,round(mean + sDevMultiple*std));

	dummy = calculateDetectorParams(i);
	print(nSPix_temp);
		

	IU			= Array.concat(IU, IU_temp);
	IU_GE		= Array.concat(IU_GE, IU_GE_temp);
	nSPix		= Array.concat(nSPix,nSPix_temp);
	sPix			= Array.concat(sPix,sPix_temp);
	sType		= Array.concat(sType,sType_temp);
	sPix_x		= Array.concat(sPix_x, sPix_x_temp);
	sPix_y		= Array.concat(sPix_y, sPix_y_temp);
	countArr		= Array.concat(countArr,nCounts);	

	lowPix		= Array.concat(lowPix,lowPix_temp);
	highPix		= Array.concat(highPix,highPix_temp);

	selectImage(1);
	run("Select None");
	run("Duplicate...", "title=Copy");
	selectImage("Copy");
	run("Scale...", "x=- y=- width="+d2s(imgSize,0)+" height="+d2s(imgSize,0)+" depth=8 interpolation=None average create title=CopyScaled");
	selectImage("CopyScaled");
	setMinAndMax(0, max);
	
	selectImage("Summary");
	run("Add Image...", "image=CopyScaled x="+d2s((imgSize+margin)*xPos+margin,0)+" y="+d2s((imgSize+margin)*yPos+margin+yOffset,0)+" opacity=100");
	
	for (j = 0;j<nSPix_temp;j++){
		makeRectangle((imgSize+margin)*xPos+margin+sPix_x_temp[j]*scale,(imgSize+margin)*yPos+margin+yOffset+sPix_y_temp[j]*scale,scale,scale);
		if (sType_temp[j]==1) color = "red";
		if (sType_temp[j]==-1) color = "blue";
		run("Overlay Options...", "stroke=none width=0 fill="+color);
		run("Add Selection...");

	}	

	selectImage("Copy");
	close();
	selectImage("CopyScaled");
	close();


	run("Select None");

}

//for (i=0;i<lengthOf(nSPix);i++){
//	print(nSPix[i]);
//}




//Add som annotations
selectImage("Summary");
setFont("SansSerif", 18,"bold");
setColor(0, 0, 255);
Overlay.drawString("Low Count", margin, margin*2, 0);
Overlay.add;
setColor(255, 0, 0);
Overlay.drawString("High Count", margin, margin*3, 0);
Overlay.add;
Overlay.show

saveAs("jpeg",path + stnName + "_" + date + "_" + time + ".jpg");

//write results to file
dummy = writeResultsToFile();

close("Input");
close("Summary");


dummy = renameDicom(fileList);

run("Quit");								//exit imageJ


//--------------------------------------------------------------------------------------------------------------------------

function renameDicom(fileList){
	
//This function renames the DICOM files (by copy and delete)

	nFiles = lengthOf(fileList);

	for (i=0;i<(nFiles);i++){
		newFileName = stnName + "_" + date + "_" + time;
		if (nFiles>1){
			newFileName = newFileName + "_" + d2s(i,0);		
		}
		newFileName = newFileName+".dcm";
		File.copy(path+fileList[i], path+newFileName); 
		File.delete(path+fileList[i]);
	}

	return 1;

}



//---------------------------------------------------------------------------------------------------------------------------

function getFiles(path){
	
	studyUID = "blaahahahahahahahahhaha"
	
	fileList = getFileList(path);               //search for files in the current directory and check their study UIDs
		
	dcmFileList = newArray();
	for (i=0; i<(lengthOf(fileList)); i++){
		if (isDicom(fileList[i])){
					dcmFileList = Array.concat(dcmFileList,fileList[i]);			
		}
	}		
	
	assFiles = newArray();
	print(lengthOf(assFiles));	

	for (i=0; i<(lengthOf(dcmFileList)); i++){
		print(path+dcmFileList[i]);
		open(path+dcmFileList[i]);
		temp = strTrim(getInfo("0008,1010"));		
		if (temp=="D530"){
			if (lengthOf(assFiles)==0){
				studyUID = strTrim(getInfo("0020,000D"));
			}
		}	
		thisStudyUID = strTrim(getInfo("0020,000D"));
			if (thisStudyUID==studyUID){
			assFiles = Array.concat(assFiles,dcmFileList[i]);
		}
		
		close();
		
	}

	fileList = assFiles;

	return fileList;

}

//----------------------------------------------------------------------------------------------------------------------------

function openAndStackImages(fileList){
	
	acqTimeArr = newArray(19);

	nFiles = lengthOf(fileList);
	for (i=0;i<nFiles;i++){
		open(path+fileList[i]);
		nImgs = nSlices();
		if (nImgs==8){ 
			rename("1-8");
			selectImage("1-8");
			dummy = extractDicom();
			totalAcqTime = totalAcqTime + acqTime;
			for (j=0;j<8;j++){
				acqTimeArr[j]=acqTime;
			}
		}
		
		if (nImgs==4){ 
			rename("9-12");
			selectImage("9-12");
			dummy = extractDicom();
			totalAcqTime = totalAcqTime + acqTime;
			for (j=8;j<12;j++){
				acqTimeArr[j]=acqTime;
			}
		}

		if (nImgs==7){ 
			rename("13-19");
			selectImage("13-19");
			dummy = extractDicom();
			totalAcqTime = totalAcqTime + acqTime;
			for (j=12;j<19;j++){
				acqTimeArr[j]=acqTime;
			}
		}
	}

	totalAcqTime = totalAcqTime/60.0;

	run("Concatenate...", "  title=[Concatenated Stacks] image1=1-8 image2=9-12 image3=13-19 image4=[-- None --]");
	
return 1;
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function calculateDetectorParams(detectorID){
	
	IU_temp		= 0;							//temporary variables
	IU_GE_temp	= 0;
	nSPix_temp	= 0;
	sPix_temp		= newArray();
	sType_temp	= newArray();
	sPix_x_temp	= newArray();
	sPix_y_temp	= newArray();    

	lowPix_temp 	= 0;
	highPix_temp	= 0;
	
	selectImage(1);
     setSlice(detectorID+1);


	getRawStatistics(nPixels, mean, min, max, std, histogram);
	IU_temp = (max-min)/(max+min);

	orgMax = max;

	xDims = round(mtxSizeX/IU_SPS);
	yDims = round(mtxSizeY/IU_SPS);

	min = 10000000.0;
	max = 0;

	
	for (i = 0;i<xDims;i++){
		for (j = 0;j<yDims;j++){
			
			//currentPixelVal = getPixel(i,j);
			
	
			
			newVal = 0;
			
			for (k = 0;k<IU_SPS;k++){
				for (l = 0;l<IU_SPS;l++){

					currentPixelVal = getPixel(i*IU_SPS+k,j*IU_SPS+l);
					//print(d2s(i*IU_SPS+k,0)+d2s(j*IU_SPS+l,0));

					newVal = newVal + currentPixelVal;

							if (currentPixelVal<lLim){
								//print(currentPixelVal);
								nSPix_temp 	= nSPix_temp + 1;
								sType_temp 	= Array.concat(sType_temp, -1);
								sPix_x_temp	= Array.concat(sPix_x_temp, i*IU_SPS+k);
								sPix_y_temp	= Array.concat(sPix_y_temp, j*IU_SPS+l);
								sPix_temp  	= Array.concat(sPix_temp, detectorID);	
								lowPix_temp++; 

								//setPixel(i*IU_SPS+k,j*IU_SPS+l,-1);
								//print(d2s(i*IU_SPS+k,0)+","+d2s(j*IU_SPS+l,0));			
							}

							if (currentPixelVal>hLim){
								nSPix_temp 	= nSPix_temp + 1;
								sType_temp 	= Array.concat(sType_temp, 1);
								sPix_x_temp	= Array.concat(sPix_x_temp, i*IU_SPS+k);
								sPix_y_temp	= Array.concat(sPix_y_temp, j*IU_SPS+l);
								highPix_temp++;
								//sPix_temp  	= Array.concat(sPix_temp, detectorID);	
								//setPixel(i*IU_SPS+k,j*IU_SPS+l,-2);
							
							}


					}
			}

			if (newVal>max) max = newVal;
			if (newVal<min) min = newVal;

		}
	}

	IU_GE_temp = (max-min)/(max+min);
	
	return 1;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function extractDicom(){

//EXTRACT DICOM information

	date 		= strTrim(getInfo("0008,0020"));        				//StudyDate
	dateXlFormat	= substring(date,0,4) + "-" +	
				  substring(date,4,6) + "-" + substring(date,6,8);		//[YYYYMMDD] -> [YY-MM-DD]
	temp			= split(getInfo("0008,0030"),".");  					//tid på  formatet hhmmss.xxxx; släng bort ".xxxx",
	time			= strTrim(temp[0]);					
	timeXlFormat	= substring(time,0,2) + ":" +	
				  substring(time,2,4) + ":" + substring(time,4,6);		//[hhmmss] -> [hh:mm:ss]

	stnName		= strTrim(getInfo("0008,1010"));      					//Station Name
	seriesDesc 	= strTrim(getInfo("0008,103E"));						//Series Description (head1 or head2 for the VG camera)
	acqTime 		= getNumericTag("0018,1242")/1000;					//Acquisition Time [ms] -> [s]
	eWinLow 		= getNumericTag("0054,0014");						//Lower limit Energy Window
	eWinHigh		= getNumericTag("0054,0015");        					//Upper limit Energy Window
	cllmtr		= strTrim(getTag("0018,1180"));	       				//Collimator name
	nCounts 		= getNumericTag("0018,0070");						//Number of counts accumulated

	pixSize     	= getNumericTag("0028,0030");						//get the pixel size
	mtxSizeX    	= getNumericTag("0028,0010");						//get the number of columns
	mtxSizeY    	= getNumericTag("0028,0011");						//get the number of rows

	return 1;

}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function writeResultsToFile(){

	resFileStr = path+stnName+"_"+date+"_"+time+".txt";	
	resFile = File.open(resFileStr);

	print(resFile,stnName);
	print(resFile,dateXlFormat);
	print(resFile,timeXlFormat);

	print(resFile,totalAcqTime);

	print(resFile,cllmtr);
	print(resFile,eWinLow);
	print(resFile,eWinHigh);

	print(resFile," ");

	for (i=0;i<lengthOf(IU_GE);i++){
		print(resFile,minArray[i]+", "+maxArray[i]+", "+d2s(IU_GE[i],3)+", "+d2s(IU[i],3)+", "+d2s(stdArray[i],3)+", "+d2s(round(countArr[i]),0)+", "+d2s(acqTimeArr[i],0)+", "+lowPix[i]+", "+highPix[i]);
	}

	//print(resFile," ");

	//	for (i=0;i<lengthOf(IU_GE);i++){
	//	print(resFile,IU[i]);
	//}

	File.close(resFile);
	return 1;

	
}


///////////////////////////////////////// UTILITY FUNCTIONS /////////////////////////////////////////////////////////////////

function strTrim(strIn){

	strIn = replace(strIn, "\\s*$", ""); //removes trailing whitespaces 
	strIn = replace(strIn, "^\\s*", ""); //removes leading whitespaces 

	return strIn;

}

function isDicom(filename) {

	extensions = newArray("dcm");
	result = false;
	for (i=0; i<extensions.length; i++) {
		if (endsWith(toLowerCase(filename), "." + extensions[i]))
			result = true;

	}
	return result;
}


function getNumericTag(tag) {

// This function returns the numeric value of the 
// specified tag (e.g., "0018,0050"). Returns NaN 
// (not-a-number) if the tag is not found or it 
// does not have a numeric value.

    value = getTag(tag);
    if (value=="") return NaN;
    index3 = indexOf(value, "\\");
    if (index3>0)
      value = substring(value, 0, index3);
    value = 0 + value; // convert to number
    return value;
}


function getTag(tag) {

// This function returns the value of the specified 
// tag  (e.g., "0010,0010") as a string. Returns "" 
// if the tag is not found.

      info = getImageInfo();
      index1 = indexOf(info, tag);
      if (index1==-1) return "";
      index1 = indexOf(info, ":", index1);
      if (index1==-1) return "";
      index2 = indexOf(info, "\n", index1);
      value = substring(info, index1+1, index2);
      return value;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function CloseAllWindows() { 
      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 

return 1;
 } 


