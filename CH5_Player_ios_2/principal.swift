//
//  main.swift
//  CH05_Player
//
//  Created by Douglas Adams on 7/3/16.
//

import CoreFoundation
import AudioToolbox
import Accelerate



struct Recorder {                       // Struct to use in the Callback
    
    var recordFile: AudioFileID?    // reference to the output file
    var recordPacket: Int64  = 0         // current packet index in output file
    var running = false                 // recording state
    var inputFile: ExtAudioFileRef?
    
}


struct floats{
    static var floatsArray = [Float]()
}
class Principio  {
    
    
    
    //--------------------------------------------------------------------------------------------------
    // MARK: Struct definition
    
    struct myInfo {
        var playbackFile: AudioFileID?                               // reference to your output file
        var packetPosition: Int64 = 0                                           // current packet index in output file
        var numPacketsToRead: UInt32 = 0                                        // number of packets to read from file
        var packetDescs: UnsafeMutablePointer<AudioStreamPacketDescription>?    // array of packet descriptions for read buffer
        
        var isDone = false                                                      // playback has completed
    }
    
    //--------------------------------------------------------------------------------------------------
    // MARK: Supporting methods
    
    //
    // we only use time here as a guideline
    // we're really trying to get somewhere between kMinBufferSize and kMaxBufferSize buffers, but not allocate too much if we don't need it
    //
    func CalculateBytesForTime (_ inAudioFile: AudioFileID,
                                inDesc: AudioStreamBasicDescription,
                                inSeconds: Double,
                                outBufferSize: UnsafeMutablePointer<UInt32>,
                                outNumPackets: UnsafeMutablePointer<UInt32>) {
        
        let kMaxBufferSize: UInt32 = 0x10000                                        // limit size to 64K
        let kMinBufferSize: UInt32 = 0x4000                                         // limit size to 16K
        
        // we need to calculate how many packets we read at a time, and how big a buffer we need.
        // we base this on the size of the packets in the file and an approximate duration for each buffer.
        //
        // first check to see what the max size of a packet is, if it is bigger than our default
        // allocation size, that needs to become larger
        var maxPacketSize: UInt32 = 0
        var propSize: UInt32  = 4
        Utility.check(AudioFileGetProperty(inAudioFile,
                                           kAudioFilePropertyPacketSizeUpperBound,
                                           &propSize,
                                           &maxPacketSize),
                      operation: "couldn't get file's max packet size")
        
        
        if inDesc.mFramesPerPacket > 0 {
            
            let numPacketsForTime = UInt32(inDesc.mSampleRate / (Double(inDesc.mFramesPerPacket) * inSeconds))
            
            outBufferSize.pointee = numPacketsForTime * maxPacketSize
            
        } else {
            // if frames per packet is zero, then the codec has no predictable packet == time
            // so we can't tailor this (we don't know how many Packets represent a time period
            // we'll just return a default buffer size
            outBufferSize.pointee = (kMaxBufferSize > maxPacketSize ? kMaxBufferSize : maxPacketSize)
        }
        
        // we're going to limit our size to our default
        if outBufferSize.pointee > kMaxBufferSize && outBufferSize.pointee > maxPacketSize {
            
            outBufferSize.pointee = kMaxBufferSize
            
        } else {
            // also make sure we're not too small - we don't want to go the disk for too small chunks
            if outBufferSize.pointee < kMinBufferSize {
                outBufferSize.pointee = kMinBufferSize
            }
        }
        outNumPackets.pointee = outBufferSize.pointee / maxPacketSize
    }
    //
    // Read bytes from a file into a buffer
    //
    // AudioQueueOutputCallback function
    //
    //      must have the following signature:
    //          @convention(c) (UnsafeMutablePointer<Swift.Void>?,                      // Void pointer to Player struct
    //                          AudioQueueRef,                                          // reference to the queue
    //                          AudioQueueBufferRef) -> Swift.Void                      // reference to the buffer in the queue
    //
    let callback : @convention(c) (_ userData : UnsafeMutableRawPointer?,
        _ queue : AudioQueueRef,
        _ bufferToFill : AudioQueueBufferRef) -> Void =
        { (userData, queue, bufferToFill) in
            // print("outputCallback")
            guard let myInfo = userData?.assumingMemoryBound(to: myInfo.self) else {return}
            //if let player = userData.UnsafeRawPointer{
            if myInfo.pointee.isDone{ return }
            
            // read audio data from file into supplied buffer
            var numBytes: UInt32 = bufferToFill.pointee.mAudioDataBytesCapacity;
            var nPackets = myInfo.pointee.numPacketsToRead
            
            let arrayFloats:[Float] = []
            let ptrArray = UnsafeMutablePointer(mutating: arrayFloats)
            //    let mean:[Float] = []
            //    let ptrMean = UnsafeMutablePointer(mutating: mean)
            
            
            
            
            //            vDSP_vflt16(buff, 1, ptrArray, 1, vDSP_Length(bufferToFill.pointee.mAudioDataByteSize / 2))
            //                vDSP_meamgv(ptrArray, 1, ptrMean, vDSP_Length(bufferToFill.pointee.mAudioDataByteSize / 2))
            //                print("values: \(mean)  \(bufferToFill.pointee.mAudioDataByteSize)")
            
            Utility.check(AudioFileReadPacketData(myInfo.pointee.playbackFile! ,              // AudioFileID
                false,                                     // use cache?
                &numBytes,                                 // initially - buffer capacity, after - bytes actually read
                myInfo.pointee.packetDescs,                // pointer to an array of PacketDescriptors
                myInfo.pointee.packetPosition,             // index of first packet to be read
                &nPackets,                                 // number of packets
                bufferToFill.pointee.mAudioData),          // output buffer
                operation: "AudioFileReadPacketData failed")
            
            //          let buff = UnsafePointer(bufferToFill.pointee.mAudioData.assumingMemoryBound(to: Int16.self))
            //          let audioData = bufferToFill.pointee.mAudioData.assumingMemoryBound(to: Float32.self)
            //
            //          let typeSize = MemoryLayout.size(ofValue: Float32.self)
            //          let size = Int((bufferToFill.pointee.mAudioDataBytesCapacity)) / 4
            //          let array = Array(UnsafeMutableBufferPointer(start: bufferToFill.pointee.mAudioData.assumingMemoryBound(to: Float32.self), count: size))
            //          print(array[0...10],"floats",typeSize)
            //          floats.floatsArray.append(contentsOf: array)
            //          print(buff.pointee, audioData.pointee)
            
            //          AudioFileReadBytes(myInfo.pointee.playbackFile!, false, 0, &numBytes, bufferToFill.pointee.mAudioData)
            //
            
            // enqueue buffer into the Audio Queue
            // if nPackets == 0 it means we are EOF (all data has been read from file)
            if nPackets > 0 {
                bufferToFill.pointee.mAudioDataByteSize = numBytes
                
                
                Utility.check(AudioQueueEnqueueBuffer(queue,                                                 // queue
                    bufferToFill,                                          // buffer to enqueue
                    (myInfo.pointee.packetDescs == nil ? 0 : nPackets),    // number of packet descriptions
                    myInfo.pointee.packetDescs),                           // pointer to a PacketDescriptions array
                    operation: "AudioQueueEnqueueBuffer failed")
                
                myInfo.pointee.packetPosition += Int64(nPackets)
                
            } else {
                
                Utility.check(AudioQueueStop(queue, false),
                              operation: "AudioQueueStop failed")
                
                myInfo.pointee.isDone = true
            }
    }
    
    //--------------------------------------------------------------------------------------------------
    // MARK: Properties
    
    let kPlaybackFileLocation = CFStringCreateWithCString(kCFAllocatorDefault, "/Users/miguelsaldana/Desktop/sample2.m4a", CFStringBuiltInEncodings.UTF8.rawValue)
    
    //#define kPlaybackFileLocation  CFSTR("/Users/cadamson/Library/Developer/Xcode/DerivedData/CH04_Recorder-dvninfofohfiwcgyndnhzarhsipp/Build/Products/Debug/output.caf")
    //#define kPlaybackFileLocation  CFSTR("/Users/cadamson/audiofile.m4a")
    //#define kPlaybackFileLocation  CFSTR("/Volumes/Sephiroth/iTunes/iTunes Media/Music/The Tubes/Tubes World Tour 2001/Wild Women of Wongo.m4p")
    //#define kPlaybackFileLocation  CFSTR("/Volumes/Sephiroth/iTunes/iTunes Media/Music/Compilations/ESCAFLOWNE - ORIGINAL MOVIE SOUNDTRACK/21 We're flying.m4a")
    
    let kNumberPlaybackBuffers = 3
    
    //--------------------------------------------------------------------------------------------------
    // MARK: Main
    func principio(){
        //    var read = readData()
        var player = myInfo()
        
        //let fileURL: CFURL  = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, kPlaybackFileLocation, .cfurlposixPathStyle, false)
        //let fileURL = Bundle.main.path(forResource:"podcast", ofType: "mp3")
        
        let path = Bundle.main.path(forResource: "shorts", ofType: "mp3")!
        let url = NSURL.fileURL(withPath: path)
        
        // open the audio file, set the playbackFile property in the player struct
        Utility.check(AudioFileOpenURL(url as CFURL,                              // file URL to open
            .readPermission,                      // open to read
            0,                                    // hint
            &player.playbackFile),                // set on output to the AudioFileID
            operation: "AudioFileOpenURL failed")
        
        
        // get the audio data format from the file
        var dataFormat = AudioStreamBasicDescription()
        var propSize = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        Utility.check(AudioFileGetProperty(player.playbackFile!,             // AudioFileID
            kAudioFilePropertyDataFormat,     // desired property
            &propSize,                        // size of the property
            &dataFormat),                     // set on output to the ASBD
            operation: "couldn't get file's data format");
        
        //
        //  dataFormat.mSampleRate = 44100.0
        //  dataFormat.mFormatID = kAudioFormatLinearPCM;
        //  dataFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat | kAudioFormatFlagsNativeEndian;
        //  dataFormat.mBitsPerChannel = 32;
        //  dataFormat.mChannelsPerFrame = 2;
        //  dataFormat.mBytesPerPacket = 4 * dataFormat.mChannelsPerFrame;
        //  dataFormat.mBytesPerFrame = 4 * dataFormat.mChannelsPerFrame;
        //  dataFormat.mFramesPerPacket = 1;
        //  dataFormat.mReserved = 0;
        
        
        Swift.print(dataFormat)
        
        // create an output (playback) queue
        var queue: AudioQueueRef? = nil
        Utility.check(AudioQueueNewOutput(&dataFormat,                       // pointer to the ASBD
            callback,                    // callback function
            &player,                           // pointer to the player struct
            CFRunLoopGetCurrent(),                               // run loop
            CFRunLoopMode.commonModes.rawValue,                               // run loop mode
            0,                                 // flags (always 0)
            &queue),                           // pointer to the queue
            operation: "AudioQueueNewOutput failed");
        
        var maxFrames : UInt32 = 0;
        var tapFormat = AudioStreamBasicDescription()
        var tap : AudioQueueProcessingTapRef? = nil
        
        Utility.check(AudioQueueProcessingTapNew(queue!, tapCallback, &player, AudioQueueProcessingTapFlags.preEffects, &maxFrames, &tapFormat, &tap), operation: "Failed to create audio queue tap")
        
        Swift.print(tapFormat)
        
        // adjust buffer size to represent about a half second (0.5) of audio based on this format
        var bufferByteSize: UInt32 = 0
        
        CalculateBytesForTime(player.playbackFile!, inDesc: dataFormat,  inSeconds: 0.5, outBufferSize: &bufferByteSize, outNumPackets: &player.numPacketsToRead)
        
        // check if we are dealing with a variable-bit-rate file. ASBDs for VBR files always have
        // mBytesPerPacket and mFramesPerPacket as 0 since they can fluctuate at any time.
        // If we are dealing with a VBR file, we allocate memory to hold the packet descriptions
        if (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0) {
            
            // variable bit rate formats
            player.packetDescs = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: MemoryLayout<AudioStreamPacketDescription>.size * Int(player.numPacketsToRead))
            
        } else {
            
            // constant bit rate formats (we don't provide packet descriptions, e.g linear PCM)
            player.packetDescs = nil;
            
        }
        
        // get magic cookie from file and set on queue
        Utility.applyEncoderCookie(fromFile: player.playbackFile!, toQueue: queue!)
        
        // allocate the buffers [nil,nil,nil]
        var buffers = [AudioQueueBufferRef?](repeating: nil, count: kNumberPlaybackBuffers)
        
        
        
        player.isDone = false
        player.packetPosition = 0
        
        // prime the queue with some data before starting
        for i in 0..<kNumberPlaybackBuffers where !player.isDone {
            
            // allocate a buffer of the specified size in the given queue
            //      places an AudioQueueBufferRef in the buffers array
            Utility.check(AudioQueueAllocateBuffer(queue!,                               // AudioQueueRef
                bufferByteSize,                       // number of bytes to allocate
                &buffers[i]),                         // on output contains an AudioQueueBufferRef
                operation: "AudioQueueAllocateBuffer failed")
            
            // manually invoke callback to fill buffers with data
            
            callback(&player, queue!, buffers[i]!)
            // print("buffer:\(i)")
            
        }
        
        // start the queue. this function returns immedatly and begins
        // invoking the callback, as needed, asynchronously.
        Utility.check(AudioQueueStart(queue!, nil), operation: "AudioQueueStart failed")
        
        Swift.print("Playing...\n");
        
        // and wait
        repeat
        {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.25, false)
        } while !player.isDone
        
        // isDone represents the state of the Audio File enqueuing. This does not mean the
        // Audio Queue is actually done playing yet. Since we have 3 half-second buffers in-flight
        // run for continue to run for a short additional time so they can be processed
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 3, false)
        
        // end playback
        player.isDone = true
        Utility.check(AudioQueueStop(queue!, true), operation: "AudioQueueStop failed");
        
        
        // cleanup
        AudioQueueDispose(queue!, true)
        AudioFileClose(player.playbackFile!)
        
        //read.readBuff(fileURL)
        
        
        let file = "floatsss.txt" //this is the file. we will write to and read from it
        
        var text = "\(floats.floatsArray)" //just a text
        text = text.replacingOccurrences(of: ",", with: "")
        text = text.replacingOccurrences(of: "[", with: "")
        text = text.replacingOccurrences(of: "]", with: "")
        
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            let fileURL = dir.appendingPathComponent(file)
            
            //writing
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
                print("successss",fileURL)
            }
            catch {/* error handling here */
                print("errorwriting")
            }
            
        }
    }
    
    let tapCallback : @convention(c) (
        _ userData : UnsafeMutableRawPointer,
        _ tap : AudioQueueProcessingTapRef,
        _ inNumFrames: UInt32 ,
        _ ts: UnsafeMutablePointer<AudioTimeStamp>,
        _ ioFlags: UnsafeMutablePointer<AudioQueueProcessingTapFlags>,
        _ outNumFrames: UnsafeMutablePointer<UInt32>,
        _ ioData: UnsafeMutablePointer<AudioBufferList>
        ) -> Void =
        {
            (userData, tap, inNumFrames, ts, ioFlags, outNumFrames, ioData) in
            
            let info = userData.assumingMemoryBound(to: myInfo.self)
            if info.pointee.isDone { return }
            
            var sourceFlags : AudioQueueProcessingTapFlags = AudioQueueProcessingTapFlags(rawValue: 0)
            var sourceNumFrames : UInt32 = 0
            
            AudioQueueProcessingTapGetSourceAudio(tap, inNumFrames, ts, &sourceFlags, &sourceNumFrames, ioData)
            
            
            print("ts:", ts.pointee)
            print("num frames:", inNumFrames)
            
            let numBuffers = ioData.pointee.mNumberBuffers
            
            print("num buffers:", numBuffers)
            
            if (numBuffers > 0)
            {
                let numChans = ioData.pointee.mBuffers.mNumberChannels
                let size = ioData.pointee.mBuffers.mDataByteSize / 4 //Size of a float is 4
                let data : [Float] = Array(UnsafeMutableBufferPointer(start: ioData.pointee.mBuffers.mData!.assumingMemoryBound(to: Float.self), count: Int(size)))
                
                print("num chans:", numChans)
                print("size:", size)
                print("data:", data[0 ... 32], "...")
            }
            
    }
}

