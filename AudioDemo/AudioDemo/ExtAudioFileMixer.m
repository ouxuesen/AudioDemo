//
//  ExtAudioFileMixer.m
//  AudioDemo
//
//  Created by 欧学森 on 08/12/2017.
//  Copyright © 2017 ouxuesen. All rights reserved.
//

#import "ExtAudioFileMixer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@implementation ExtAudioFileMixer

+ (OSStatus)mixAudio:(NSString *)audioPath1
            andAudio:(NSString *)audioPath2
              toFile:(NSString *)outputPath
  preferedSampleRate:(float)sampleRate
{
    OSStatus                            err = noErr;
    AudioStreamBasicDescription         inputFileFormat1;
    AudioStreamBasicDescription         inputFileFormat2;
    AudioStreamBasicDescription         converterFormat;
    UInt32                              thePropertySize = sizeof(inputFileFormat1);
    ExtAudioFileRef                     inputAudioFileRef1 = NULL;
    ExtAudioFileRef                     inputAudioFileRef2 = NULL;
    ExtAudioFileRef                     outputAudioFileRef = NULL;
    AudioStreamBasicDescription         outputFileFormat;
    
    NSURL *inURL1 = [NSURL fileURLWithPath:audioPath1];
    NSURL *inURL2 = [NSURL fileURLWithPath:audioPath2];
    NSURL *outURL = [NSURL fileURLWithPath:outputPath];
    
    // Open input audio file
    
    err = ExtAudioFileOpenURL((__bridge CFURLRef)inURL1, &inputAudioFileRef1);
    if (err)
    {
        goto reterr;
    }
    assert(inputAudioFileRef1);
    
    err = ExtAudioFileOpenURL((__bridge CFURLRef)inURL2, &inputAudioFileRef2);
    if (err)
    {
        goto reterr;
    }
    assert(inputAudioFileRef2);
    
    // Get input audio format
    
    bzero(&inputFileFormat1, sizeof(inputFileFormat1));
    err = ExtAudioFileGetProperty(inputAudioFileRef1, kExtAudioFileProperty_FileDataFormat,
                                  &thePropertySize, &inputFileFormat1);
    if (err)
    {
        goto reterr;
    }
    
    // only mono or stereo audio files are supported
    
    if (inputFileFormat1.mChannelsPerFrame > 2)
    {
        err = kExtAudioFileError_InvalidDataFormat;
        goto reterr;
    }
    
    bzero(&inputFileFormat2, sizeof(inputFileFormat2));
    err = ExtAudioFileGetProperty(inputAudioFileRef2, kExtAudioFileProperty_FileDataFormat,
                                  &thePropertySize, &inputFileFormat2);
    if (err)
    {
        goto reterr;
    }
    
    // only mono or stereo audio files are supported
    
    if (inputFileFormat2.mChannelsPerFrame > 2)
    {
        err = kExtAudioFileError_InvalidDataFormat;
        goto reterr;
    }
    
    int numChannels = MAX(inputFileFormat1.mChannelsPerFrame, inputFileFormat2.mChannelsPerFrame);
    
    // Enable an audio converter on the input audio data by setting
    // the kExtAudioFileProperty_ClientDataFormat property. Each
    // read from the input file returns data in linear pcm format.
    
    AudioFileTypeID audioFileTypeID = kAudioFileCAFType;
    
    Float64 mSampleRate = sampleRate? sampleRate : MAX(inputFileFormat1.mSampleRate, inputFileFormat2.mSampleRate);
    
    [self _setDefaultAudioFormatFlags:&converterFormat sampleRate:mSampleRate numChannels:inputFileFormat1.mChannelsPerFrame];
    
    err = ExtAudioFileSetProperty(inputAudioFileRef1, kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(converterFormat), &converterFormat);
    if (err)
    {
        goto reterr;
    }
    [self _setDefaultAudioFormatFlags:&converterFormat sampleRate:mSampleRate numChannels:inputFileFormat2.mChannelsPerFrame];
    err = ExtAudioFileSetProperty(inputAudioFileRef2, kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(converterFormat), &converterFormat);
    if (err)
    {
        goto reterr;
    }
    // Handle the case of reading from a mono input file and writing to a stereo
    // output file by setting up a channel map. The mono output is duplicated
    // in the left and right channel.
    
    if (inputFileFormat1.mChannelsPerFrame == 1 && numChannels == 2) {
        SInt32 channelMap[2] = { 0, 0 };
        
        // Get the underlying AudioConverterRef
        
        AudioConverterRef convRef = NULL;
        UInt32 size = sizeof(AudioConverterRef);
        
        err = ExtAudioFileGetProperty(inputAudioFileRef1, kExtAudioFileProperty_AudioConverter, &size, &convRef);
        
        if (err)
        {
            goto reterr;
        }
        
        assert(convRef);
        
        err = AudioConverterSetProperty(convRef, kAudioConverterChannelMap, sizeof(channelMap), channelMap);
        
        if (err)
        {
            goto reterr;
        }
    }
    if (inputFileFormat2.mChannelsPerFrame == 1 && numChannels == 2) {
        SInt32 channelMap[2] = { 0, 0 };
        
        // Get the underlying AudioConverterRef
        
        AudioConverterRef convRef = NULL;
        UInt32 size = sizeof(AudioConverterRef);
        
        err = ExtAudioFileGetProperty(inputAudioFileRef2, kExtAudioFileProperty_AudioConverter, &size, &convRef);
        
        if (err)
        {
            goto reterr;
        }
        
        assert(convRef);
        
        err = AudioConverterSetProperty(convRef, kAudioConverterChannelMap, sizeof(channelMap), channelMap);
        
        if (err)
        {
            goto reterr;
        }
    }
    // Output file is typically a caff file, but the user could emit some other
    // common file types. If a file exists already, it is deleted before writing
    // the new audio file.
    
    [self _setDefaultAudioFormatFlags:&outputFileFormat sampleRate:mSampleRate numChannels:numChannels];
    
    UInt32 flags = kAudioFileFlags_EraseFile;
    
    err = ExtAudioFileCreateWithURL((__bridge CFURLRef)outURL, audioFileTypeID, &outputFileFormat,
                                    NULL, flags, &outputAudioFileRef);
    if (err)
    {
        // -48 means the file exists already
        goto reterr;
    }
    assert(outputAudioFileRef);
    
    // Enable converter when writing to the output file by setting the client
    // data format to the pcm converter we created earlier.
    
    err = ExtAudioFileSetProperty(outputAudioFileRef, kExtAudioFileProperty_ClientDataFormat,
                                  sizeof(outputFileFormat), &outputFileFormat);
    if (err)
    {
        goto reterr;
    }
    
    // Buffer to read from source file and write to dest file
    
    UInt16 bufferSize = 8192;
    
    AudioSampleType * buffer1 = malloc(bufferSize);
    AudioSampleType * buffer2 = malloc(bufferSize);
    AudioSampleType * outBuffer = malloc(bufferSize);
    
    AudioBufferList conversionBuffer1;
    conversionBuffer1.mNumberBuffers = 1;
    conversionBuffer1.mBuffers[0].mNumberChannels = inputFileFormat1.mChannelsPerFrame;
    conversionBuffer1.mBuffers[0].mDataByteSize = bufferSize;
    conversionBuffer1.mBuffers[0].mData = buffer1;
    
    AudioBufferList conversionBuffer2;
    conversionBuffer2.mNumberBuffers = 1;
    conversionBuffer2.mBuffers[0].mNumberChannels = inputFileFormat2.mChannelsPerFrame;
    conversionBuffer2.mBuffers[0].mDataByteSize = bufferSize;
    conversionBuffer2.mBuffers[0].mData = buffer2;
    
    //
    AudioBufferList outBufferList;
    outBufferList.mNumberBuffers = 1;
    outBufferList.mBuffers[0].mNumberChannels = outputFileFormat.mChannelsPerFrame;
    outBufferList.mBuffers[0].mDataByteSize = bufferSize;
    outBufferList.mBuffers[0].mData = outBuffer;
    
    UInt32 numFramesToReadPerTime = INT_MAX;
    UInt8 bitOffset = 8 * sizeof(AudioSampleType);
    UInt64 bitMax = (UInt64) (pow(2, bitOffset));
    UInt64 bitMid = bitMax/2;
    
    
    while (TRUE) {
        conversionBuffer1.mBuffers[0].mDataByteSize = bufferSize;
        conversionBuffer2.mBuffers[0].mDataByteSize = bufferSize;
        outBufferList.mBuffers[0].mDataByteSize = bufferSize;
        
        UInt32 frameCount1 = numFramesToReadPerTime;
        UInt32 frameCount2 = numFramesToReadPerTime;
        
        if (inputFileFormat1.mBytesPerFrame)
        {
            frameCount1 = bufferSize/inputFileFormat1.mBytesPerFrame;
        }
        if (inputFileFormat2.mBytesPerFrame)
        {
            frameCount2 = bufferSize/inputFileFormat2.mBytesPerFrame;
        }
        // Read a chunk of input
        
        err = ExtAudioFileRead(inputAudioFileRef1, &frameCount1, &conversionBuffer1);
        
        if (err) {
            goto reterr;
        }
        
        err = ExtAudioFileRead(inputAudioFileRef2, &frameCount2, &conversionBuffer2);
        
        if (err) {
            goto reterr;
        }
        // If no frames were returned, conversion is finished
        
        if (frameCount1 == 0 && frameCount2 == 0)
            break;
        
        UInt32 frameCount = MAX(frameCount1, frameCount2);
        UInt32 minFrames = MIN(frameCount1, frameCount2);
        
        outBufferList.mBuffers[0].mDataByteSize = frameCount * outputFileFormat.mBytesPerFrame;
        
        UInt32 length = frameCount * 2;
        for (int j =0; j < length; j++)
        {
            if (j/2 < minFrames)
            {
                SInt32 sValue =0;
                
                SInt16 value1 = (SInt16)*(buffer1+j);   //-32768 ~ 32767
                SInt16 value2 = (SInt16)*(buffer2+j);   //-32768 ~ 32767
                
                SInt8 sign1 = (value1 == 0)? 0 : abs(value1)/value1;
                SInt8 sign2 = (value2== 0)? 0 : abs(value2)/value2;
                
                if (sign1 == sign2)
                {
                    UInt32 tmp = ((value1 * value2) >> (bitOffset -1));
                    
                    sValue = value1 + value2 - sign1 * tmp;
                    
                    if (abs(sValue) >= bitMid)
                    {
                        sValue = sign1 * (bitMid -  1);
                    }
                }
                else
                {
                    SInt32 tmpValue1 = value1 + bitMid;
                    SInt32 tmpValue2 = value2 + bitMid;
                    
                    UInt32 tmp = ((tmpValue1 * tmpValue2) >> (bitOffset -1));
                    
                    if (tmpValue1 < bitMid && tmpValue2 < bitMid)
                    {
                        sValue = tmp;
                    }
                    else
                    {
                        sValue = 2 * (tmpValue1  + tmpValue2 ) - tmp - bitMax;
                    }
                    sValue -= bitMid;
                }
                
                if (abs(sValue) >= bitMid)
                {
                    SInt8 sign = abs(sValue)/sValue;
                    
                    sValue = sign * (bitMid -  1);
                }
                
                *(outBuffer +j) = sValue;
            }
            else{
                if (frameCount == frameCount1)
                {
                    //将buffer1中的剩余数据添加到outbuffer
                    *(outBuffer +j) = *(buffer1 + j);
                }
                else
                {
                    //将buffer1中的剩余数据添加到outbuffer
                    *(outBuffer +j) = *(buffer2 + j);
                }
            }
        }
        
        // Write pcm data to output file
        NSLog(@"frame count (%ld, %ld, %ld)", frameCount, frameCount1, frameCount2);
        err = ExtAudioFileWrite(outputAudioFileRef, frameCount, &outBufferList);
        
        if (err) {
            goto reterr;
        }
    }
    
reterr:
    if (buffer1)
        free(buffer1);
    
    if (buffer2)
        free(buffer2);
    
    if (outBuffer)
        free(outBuffer);
    
    if (inputAudioFileRef1)
        ExtAudioFileDispose(inputAudioFileRef1);
    
    if (inputAudioFileRef2)
        ExtAudioFileDispose(inputAudioFileRef2);
    
    if (outputAudioFileRef)
        ExtAudioFileDispose(outputAudioFileRef);
    
    return err;
}

// Set flags for default audio format on iPhone OS

+ (void) _setDefaultAudioFormatFlags:(AudioStreamBasicDescription*)audioFormatPtr
                          sampleRate:(Float64)sampleRate
                         numChannels:(NSUInteger)numChannels
{
    bzero(audioFormatPtr, sizeof(AudioStreamBasicDescription));
    
    audioFormatPtr->mFormatID = kAudioFormatLinearPCM;
    audioFormatPtr->mSampleRate = sampleRate;
    audioFormatPtr->mChannelsPerFrame = numChannels;
    audioFormatPtr->mBytesPerPacket = 2 * numChannels;
    audioFormatPtr->mFramesPerPacket = 1;
    audioFormatPtr->mBytesPerFrame = 2 * numChannels;
    audioFormatPtr->mBitsPerChannel = 16;
    audioFormatPtr->mFormatFlags = kAudioFormatFlagsNativeEndian |
    kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
}

//生成视频mp4.
+ (void)sourceURLs:(NSArray *) sourceURLs videoUrl:(NSURL*)videoUrl composeToURL:(NSURL *) toURL completed:(void (^)(NSError *error)) completed;
{
    
    __block NSError * error = nil;
    AVURLAsset *videoAsset = [AVURLAsset assetWithURL:videoUrl];
    
    AVMutableComposition *compostion = [AVMutableComposition composition];
    AVMutableCompositionTrack *video = [compostion addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:0];
    [video insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:[videoAsset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:&error];
    NSArray* audioArray = [videoAsset tracksWithMediaType:AVMediaTypeAudio];
    NSLog(@"audoArray = %@",audioArray);
    for (AVAssetTrack*audioTranck in audioArray) {
     
        AVMutableCompositionTrack *audieo_Video = [compostion addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
        [audieo_Video insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration) ofTrack:audioTranck atTime:kCMTimeZero error:&error];
    }
   
    for (NSURL*audioUrl in sourceURLs) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:audioUrl.path])
        {
            AVURLAsset *audioAsset = [AVURLAsset assetWithURL:audioUrl];
            AVMutableCompositionTrack *audio = [compostion addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
            [audio insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset.duration) ofTrack:[audioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:kCMTimeZero error:&error];
        }
    }
    
    AVAssetExportSession *session = [[AVAssetExportSession alloc]initWithAsset:compostion presetName:AVAssetExportPresetMediumQuality];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:toURL.path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:toURL.path error:nil];
    }
    NSLog(@"%@",session.supportedFileTypes);
    session.outputURL = toURL;
    session.outputFileType = @"com.apple.quicktime-movie";
    session.shouldOptimizeForNetworkUse = YES;
    [session exportAsynchronouslyWithCompletionHandler:^{
        if ([[NSFileManager defaultManager] fileExistsAtPath:toURL.path])
        {
            // 调用播放方法
            completed?completed(error):nil;
        }
        else
        {
            NSLog(@"输出错误");
            completed?completed(error):nil;
        }
    }];
    
}
//wav头的结构如下所示：
-(BOOL)convertPcm2Wav:(NSString*)src_file dst_file:(NSString*)dst_file channels:(int)channels sample_rate:(int)sample_rate
{
    return convertPcm2Wav((char*)[src_file UTF8String],(char*)[dst_file UTF8String], channels, sample_rate );
}
typedef  struct  {
    
    char        fccID[4];
    
    int32_t      dwSize;
    
    char        fccType[4];
    
} HEADER;

typedef  struct  {
    
    char        fccID[4];
    
    int32_t      dwSize;
    
    int16_t      wFormatTag;
    
    int16_t      wChannels;
    
    int32_t      dwSamplesPerSec;
    
    int32_t      dwAvgBytesPerSec;
    
    int16_t      wBlockAlign;
    
    int16_t      uiBitsPerSample;
    
}FMT;

typedef  struct  {
    
    char        fccID[4];
    
    int32_t      dwSize;
    
}DATA;

int convertPcm2Wav(char  *src_file, char  *dst_file, int channels, int sample_rate)

{
    
    int bits = 16;
    
    //以下是为了建立.wav头而准备的变量
    
    HEADER  pcmHEADER;
    
    FMT  pcmFMT;
    
    DATA  pcmDATA;
    
    unsigned  short  m_pcmData;
    
    FILE  *fp,*fpCpy;
    
    if((fp=fopen(src_file,  "rb"))  ==  NULL) //读取文件
        
    {
        
        printf("open pcm file %s error\n", src_file);
        
        return -1;
        
    }
    
    if((fpCpy=fopen(dst_file,  "wb+"))  ==  NULL) //为转换建立一个新文件
        
    {
        
        printf("create wav file error\n");
        
        return -1;
        
    }
    
    //以下是创建wav头的HEADER;但.dwsize未定，因为不知道Data的长度。
    
    strncpy(pcmHEADER.fccID,"RIFF",4);
    
    strncpy(pcmHEADER.fccType,"WAVE",4);
    
    fseek(fpCpy,sizeof(HEADER),1); //跳过HEADER的长度，以便下面继续写入wav文件的数据;
    
    //以上是创建wav头的HEADER;
    
    if(ferror(fpCpy))
        
    {
        
        printf("error\n");
        
    }
    
    //以下是创建wav头的FMT;
    
    pcmFMT.dwSamplesPerSec=sample_rate;
    
    pcmFMT.dwAvgBytesPerSec=pcmFMT.dwSamplesPerSec*sizeof(m_pcmData);
    
    pcmFMT.uiBitsPerSample=bits;
    
    strncpy(pcmFMT.fccID,"fmt  ", 4);
    
    pcmFMT.dwSize=16;
    
    pcmFMT.wBlockAlign=2;
    
    pcmFMT.wChannels=channels;
    
    pcmFMT.wFormatTag=1;
    
    //以上是创建wav头的FMT;
    
    fwrite(&pcmFMT,sizeof(FMT),1,fpCpy); //将FMT写入.wav文件;
    
    //以下是创建wav头的DATA;  但由于DATA.dwsize未知所以不能写入.wav文件
    
    strncpy(pcmDATA.fccID,"data", 4);
    
    pcmDATA.dwSize=0; //给pcmDATA.dwsize  0以便于下面给它赋值
    
    fseek(fpCpy,sizeof(DATA),1); //跳过DATA的长度，以便以后再写入wav头的DATA;
    
    fread(&m_pcmData,sizeof(int16_t),1,fp); //从.pcm中读入数据
    
    while(!feof(fp)) //在.pcm文件结束前将他的数据转化并赋给.wav;
        
    {
        
        pcmDATA.dwSize+=2; //计算数据的长度；每读入一个数据，长度就加一；
        
        fwrite(&m_pcmData,sizeof(int16_t),1,fpCpy); //将数据写入.wav文件;
        
        fread(&m_pcmData,sizeof(int16_t),1,fp); //从.pcm中读入数据
        
    }
    
    fclose(fp); //关闭文件
    
    pcmHEADER.dwSize = 0;  //根据pcmDATA.dwsize得出pcmHEADER.dwsize的值
    
    rewind(fpCpy); //将fpCpy变为.wav的头，以便于写入HEADER和DATA;
    
    fwrite(&pcmHEADER,sizeof(HEADER),1,fpCpy); //写入HEADER
    
    fseek(fpCpy,sizeof(FMT),1); //跳过FMT,因为FMT已经写入
    
    fwrite(&pcmDATA,sizeof(DATA),1,fpCpy);  //写入DATA;
    
    fclose(fpCpy);  //关闭文件
    
    return 0;
    
}


@end
