#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define PCM 1

const char* outputFilename = "out.wav";

extern void callMe(char* dest, const char* src,int newSize,int blockAlign, int m);

static int getInt(){
    char line[128];
    fgets(line,128,stdin);
    line[strcspn(line, "\n")] = 0;
    return atoi(line);
}

static void writeLittleEndian(char* buffer,int n, int size){
    int shift = 0;
    for(int i = 0; i < size; i++){
        buffer[i] = (char)((n >> shift) & 0xff);
        shift += 8;
    }
}

static int32_t readLittleEndian(const char* buffer, int size){
    int32_t  n = 0;
    int shift = 0;

    for(int i=0; i < size; i++){
        n += ((uint8_t)buffer[i]) << shift;
        shift += 8;
    }

    return n;
}

static const char* strfind(const char* hay,int haySize, const char* needle, int needleSize){

    const char*  result = NULL;

    for(int i = 0; i < (haySize - needleSize); i++){
        if(hay[i] == needle[0]){
            result = hay + i;

            for(int j = 0; j < needleSize; j++){
                if(hay[i+j] != needle[j]){
                    result = NULL;
                    break;
                }
            }

            if(result != NULL)
                break;
        }
    }

    return result;
}

static char *readFile(const char *path) {

  FILE *file = fopen(path, "rb");
  if (file == NULL) {
    fprintf(stderr, "Could not open file \"%s\".\n", path);
    exit(1);
  }

  fseek(file, 0L, SEEK_END);
  size_t fileSize = ftell(file);
  rewind(file);

  char *buffer = (char *)malloc(fileSize + 1);
  if (buffer == NULL) {
    fprintf(stderr, "Not enough memory to read \"%s\".\n", path);
    exit(1);
  }

  size_t bytesRead = fread(buffer, sizeof(char), fileSize, file);
  if (bytesRead < fileSize) {
    fprintf(stderr, "Could not read file \"%s\".\n", path);
    exit(1);
  }

  buffer[bytesRead] = '\0';
  fclose(file);

  return buffer;
}

int main(){
    char inputFilename[128];

    printf("Enter the name of the wav file: ");
    fgets(inputFilename,128, stdin);

    inputFilename[strcspn(inputFilename, "\n")] = 0;

    char* file = readFile(inputFilename);

    if(strncmp(file,"RIFF",4) == 0 && strncmp(file+8,"WAVE",4) == 0){

        int32_t fileSize = readLittleEndian(file+4,4);
        printf("the size of the file is %d\n",fileSize);

        const char* fmtChunk = strfind(file, fileSize, "fmt ", 4);

        if(fmtChunk == NULL){
            fprintf(stderr,"The file doesn't contain a fmt chunk.");
            exit(1);
        }

        int32_t fmtChunkSize = readLittleEndian(fmtChunk+4, 4);
        printf("the fmtChuckSize is %d\n",fmtChunkSize);
        int32_t audioFormat = readLittleEndian(fmtChunk+8, 2);
        printf("the audioFormat is %d\n",audioFormat);
        int32_t blockAlign = readLittleEndian(fmtChunk+20, 2);
        printf("the blockAlign is %d\n",blockAlign);

        if(audioFormat != PCM){
            fprintf(stderr,"This program only works on PCM wav files.");
            exit(1);
        }

        const char* dataChunk = strfind(file, fileSize, "data", 4);

        if(dataChunk == NULL){
            fprintf(stderr,"The wav file doesn't contain a data chunk.\n");
            exit(1);
        }

        int32_t dataChunkSize = readLittleEndian(dataChunk+4, 4);
        printf("the dataChunkSize is %d\n", dataChunkSize);

        printf("Enter a value for m: ");

        int m = getInt();

        while(m <= 0){
            printf("The input must be a positive number.\n");
            printf("Enter a valid value for m: ");
            int m = getInt();
        }

        // Hay que sumarle el residuo y assembly para contar con el ultimo bloque
        int newDataChunkSize = (dataChunkSize/(blockAlign*m))*blockAlign;

        if((dataChunkSize % (blockAlign*m) > blockAlign)){
            newDataChunkSize += blockAlign;
        }

        printf("the newDataChunkSize is %d\n", newDataChunkSize);

        int newFileSize = 12 + 8 + fmtChunkSize + 8 + newDataChunkSize;
        printf("the newFileSize is %d\n", newFileSize);

        char* newFile = malloc(newFileSize*sizeof(char));

        if (newFile == NULL) {
            fprintf(stderr, "Not enough memory to create new file.");
            exit(1);
        }

        strncpy(newFile,"RIFF",4);
        writeLittleEndian(newFile+4,newFileSize-8,4);
        strncpy(newFile+8,"WAVE",4);

        char* newFmtChunk = newFile + 12;
        memcpy(newFmtChunk,fmtChunk, fmtChunkSize + 8);

        char* newDataChunk = newFmtChunk + fmtChunkSize + 8;
        strncpy(newDataChunk,"data",4);
        writeLittleEndian(newDataChunk+4,newDataChunkSize,4);

        const char* dataChuckBlock = dataChunk + 8;
        char* newDataChunkBlock = newDataChunk + 8;

        // Aqui se debe llamar la funcion en assembly
        callMe(newDataChunkBlock, dataChuckBlock, newDataChunkSize, blockAlign, m);

        FILE* outputFile = fopen(outputFilename, "wb");

        if (file == NULL) {
            fprintf(stderr, "Could not open file \"%s\".\n", outputFilename);
            exit(1);
        }

        fwrite(newFile, sizeof(char), newFileSize*sizeof(char), outputFile);

        fclose(outputFile);

    }else{
        fprintf(stderr,"The file is not a wav file.\n");
        exit(1);
    }

    return 0;
}
