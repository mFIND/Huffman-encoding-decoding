#include <iostream>
#include <string>
#include <cstdio>
#include <iomanip>

extern "C" void errorWithFile();
extern "C" void generalFailure();
extern "C" FILE* chooseInput();
extern "C" FILE* chooseOutput();
extern "C" int enORdeCODE();
extern "C" void terminatingAtUserRequest();
extern "C" void printLetterStatistic(int,int,int,int);
extern "C" void p(int);
extern "C" void n(int,int,int,int,int,int);
extern "C" void w();
extern "C" void z();

void w(){
	std::cout<<"\nAla ma kota..";
}
void z(){
	std::cout<<"\nAla nie ma kota..";
}

void n(const int i1, const int i2, const int i3, const int i4, const int i5, const int i6){
	std::cout<<"\n1/2/3/4/5/6 : "<<i1<<"/"<<i2<<"/"<<i3<<"/"<<i4<<"/"<<i5<<"/"<<i6;
}
void p(const int i){
	std::cout<<"\nALAMA KOTA    Value: "<<i;
}

void printLetterStatistic(int count, int lett, int code, int len){
	std::cout<<std::left<<"\n~> Statistic data: Letter value : "<<std::setw(4)<<lett<<" ("<<(char)lett<<") "<< " Count : "<<std::setw(8)<<count
	<<" Length : "<<std::setw(2)<<len<< " Code : "<<std::setw(4)<<code<<" / "<<std::hex<<"0x"<<std::setw(8)<<code<<std::dec;
	if(len == 9 && code != 0)
		std::cout<<"   <-- only zeroes for code => + 1";
}

int enORdeCODE(){
	int result;
	std::cout<<"Enter 0 encode, 1 to decode \
or any other number to terminate: ";
	std::cin>>result;
	return result;
}

void remove__n(std::string &toRemoveN){
	for(int i = 0; i < toRemoveN.size(); ++i){
		if(toRemoveN[i] == '\n')
			toRemoveN[i] = '\0';
	}
}

void generalFailure(){
	std::cout<<"General failure!"<<std::endl;
}
void errorWithFile(){
	std::cout<<"Error opening the file!"<<std::endl;
}
void terminatingAtUserRequest(){
	std::cout<<"Terminating at user request!"<<std::endl;
}

FILE* chooseInput(){
	std::string fileLoc;
	FILE* stream;
	std::cout<<"Enter path to your input file: ";
	std::cin>>fileLoc;
	stream = fopen (fileLoc.c_str(),"rb");
	return stream;
}

FILE* chooseOutput(){
	std::string fileLoc;
	FILE* stream;
	std::cout<<"Enter path to where you wish \
to save your output file: ";
	std::cin>>fileLoc;
	stream = fopen (fileLoc.c_str(),"wb");
	return stream;
}
