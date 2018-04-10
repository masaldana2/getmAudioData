////
////  readData.swift
////  SwiftCoreAudio
////
////  Created by Miguel  Saldana on 9/30/16.
////  Copyright © 2016 Douglas Adams. All rights reserved.
////
//
//import Foundation
//import AudioToolbox
//import Accelerate
//
//class readData {
//    
//    func readBuff(_ fileURL:CFURL) {
//        var recorder = Recorder()
//        
//        let openStatus = ExtAudioFileOpenURL(fileURL , &recorder.inputFile)
//        
//        
//        guard openStatus == noErr else {
//            print("Failed to open audio file '\(fileURL)' with error \(openStatus)")
//            return
//        }
//        
//        var audioFormat2 = AudioStreamBasicDescription()
//        audioFormat2.mSampleRate = 44100;   // GIVE YOUR SAMPLING RATE
//        audioFormat2.mFormatID = kAudioFormatLinearPCM
//        audioFormat2.mFormatFlags = kLinearPCMFormatFlagIsFloat
//        audioFormat2.mBitsPerChannel = UInt32(MemoryLayout<Float32>.size) * 8
//        audioFormat2.mChannelsPerFrame = 1; // Mono
//        audioFormat2.mBytesPerFrame = audioFormat2.mChannelsPerFrame * UInt32(MemoryLayout<Float32>.size);  // == sizeof(Float32)
//        audioFormat2.mFramesPerPacket = 1;
//        audioFormat2.mBytesPerPacket = audioFormat2.mFramesPerPacket * audioFormat2.mBytesPerFrame; // = sizeof(Float32)
//        
//        //apply audioFormat2 to the extended audio file
//        ExtAudioFileSetProperty(recorder.inputFile!, kExtAudioFileProperty_ClientDataFormat,UInt32(MemoryLayout<AudioStreamBasicDescription>.size),&audioFormat2)
//        
//        let numSamples = 1024 //How many samples to read in at a startTime
//        let sizePerPacket:UInt32 = audioFormat2.mBytesPerPacket // sizeof(Float32) = 32 byts
//        let packetsPerBuffer:UInt32 = UInt32(numSamples)
//        let outputBufferSize:UInt32 = packetsPerBuffer * sizePerPacket //4096
//        
//        //so the 1 value of outputbuffer is a the memory location where we have reserved space
//        let outputbuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: MemoryLayout<UInt8>.size * Int(outputBufferSize))
//        
//        
//        var convertedData = AudioBufferList()
//        convertedData.mNumberBuffers = 1 //set this for Mono
//        convertedData.mBuffers.mNumberChannels = audioFormat2.mChannelsPerFrame // also = 1
//        convertedData.mBuffers.mDataByteSize = outputBufferSize
//        convertedData.mBuffers.mData = UnsafeMutableRawPointer(outputbuffer)
//        
//        var floatDataArray:[Float] = [882000]// SPECIFY YOUR DATA LIMIT MINE WAS 882000 , SHOULD BE EQUAL TO OR MORE THAN DATA LIMIT
//        
//        var frameCount:UInt32 = UInt32(numSamples)
//        while (frameCount > 0) {
//            Utility.check(ExtAudioFileRead(recorder.inputFile!,
//                                           &frameCount,
//                                           &convertedData),
//                          operation: "Couldn't read from input file")
//            
//            if frameCount == 0 {
//                Swift.print("done reading from file")
//                return
//            }
//            
//            var arrayFloats:[Float] = []
//            let ptr = convertedData.mBuffers.mData?.assumingMemoryBound(to: Float.self)
//            
//            var j = 0
//            
//            
//            if(frameCount > 0){
//                var audioBuffer:AudioBuffer = convertedData.mBuffers
//                
//                let floatArr = UnsafeBufferPointer(start: audioBuffer.mData?.assumingMemoryBound(to: Float.self), count: 882000)
//                
//                for i in 0...1024{
//                    //floatDataArray[j] = Double(floatArr[i]) //put your data into float array
//                    // print("\(floatDataArray[j])")
//                    floatDataArray.append(floatArr[i])
//                    
//                    
//                    // print(Float((ptr?[i])!))
//                    
//                    
//                    j += 1
//                }
//                //print(floatDataArray)
//                frameCount = 0
//                convertDB(floatArr: floatDataArray)
//                
//            }
//            
//            
//        }
//        AudioFileClose(recorder.inputFile!)
//        ExtAudioFileDispose(recorder.inputFile!)
//    }
//    
////--------------------------------------------------------------------------------------------------
//// MARK: Convert linear to Decibel
//    
//    func convertDB(floatArr: [Float]){
//        //print(floatArr)
//    var floatArrPtr = UnsafeMutablePointer(mutating: floatArr)
//        
//    let sampleCount = vDSP_Length(floatArr.count)
//        print(sampleCount)
//    
//    // take the absolute values to get amplitude
//    vDSP_vabs(floatArrPtr, 1, floatArrPtr, 1, sampleCount)
//    //print(floatArr)
//        
//    // convert do dB
//    var zero:Float = 1;
//    vDSP_vdbcon(floatArrPtr, 1, &zero, floatArrPtr, 1, sampleCount, 1);
//    //print(floatArr)
//        
//    // clip to [noiseFloor, 0]
//    var noiseFloor:Float = -50.0
//    var ceil:Float = 0.0
//    vDSP_vclip(floatArrPtr, 1, &noiseFloor, &ceil,
//                   floatArrPtr, 1, sampleCount);
//    //print(floatArr)
//        
//    var samplesPerPixel = 1
//    var filter = [Float](repeating: 1.0 / Float(samplesPerPixel),
//                             count: Int(samplesPerPixel))
//    var downSampledLength = Int(floatArr.count / samplesPerPixel)
//    var downSampledData = [Float](repeating:0.0,
//                                      count:downSampledLength)
//    vDSP_desamp(floatArrPtr,
//                    vDSP_Stride(samplesPerPixel),
//                    filter, &downSampledData,
//                    vDSP_Length(downSampledLength),
//                    vDSP_Length(samplesPerPixel))
//    print(downSampledData)
//    
//    }
//}
//
//
//
//
//
//
//
//
//
//
//
//
//
//
