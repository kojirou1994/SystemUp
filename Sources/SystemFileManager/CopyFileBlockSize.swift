import SystemUp

struct BlockSizes {
  let cb_src_bsize: Int
  let cb_dst_bsize: Int
  let cb_src_minbsize: Int
  let cb_dst_minbsize: Int

  init(src: FileDescriptor, srcStat: FileStatus, dst: FileDescriptor) {
    var iBlocksize = 0, iMinblocksize = 0;
    var oBlocksize = 0, oMinblocksize = 0; // If 0, we don't support sparse copying.
    let blocksize_limit = 1 << 30; // 1 GiB

    var sfs: FileSystemStatistics = Memory.zeroed()

    // Get default and fall-back values for the input blocksize.
    do {
      try SystemCall.fileSystemStatistics(src, into: &sfs)
      #if os(macOS)
      iBlocksize = Int(sfs.ioSize)
      #else
      iBlocksize = Int(sfs.blockSize)
      #endif
      iMinblocksize = Int(sfs.blockSize)
    } catch {
      iBlocksize = Int(srcStat.blockSize)
    }

    // Get default and fall-back values for the output blocksize.
    do {
      try SystemCall.fileSystemStatistics(dst, into: &sfs)
      #if os(macOS)
      oBlocksize = (sfs.ioSize == 0) ? iBlocksize : min(Int(sfs.ioSize), iBlocksize)
      #else
      oBlocksize = iBlocksize
      #endif
      oMinblocksize = Int(sfs.blockSize)
    } catch {
      oBlocksize = iBlocksize
    }

    // If the user has provided a valid source blocksize, use it instead.
//    if (s->src_bsize >= iMinblocksize) {
//      iBlocksize = s->src_bsize;
//    }

    // If the user has provided a valid destination blocksize, use it instead,
    // unless it is larger than the source blocksize.
//    if (s->dst_bsize >= oMinblocksize && s->dst_bsize <= iBlocksize) {
//      oBlocksize = s->dst_bsize;
//    }

    // 6453525 and 34848916 require us to limit our blocksize to resonable values.
    if (srcStat.size < iBlocksize && iMinblocksize > 0) {
      //copyfile_debug(3, "rounding up block size from fsize: %lld to multiple of %zu\n",
      //               s->sb.st_size, iMinblocksize);
      iBlocksize = roundup(Int(srcStat.size), iMinblocksize)
      oBlocksize = min(oBlocksize, iBlocksize)
    }

    if (iBlocksize > blocksize_limit) {
      iBlocksize = blocksize_limit;
      oBlocksize = min(oBlocksize, iBlocksize)
    }

    // Save our decided values.
    cb_src_bsize = iBlocksize
    cb_src_minbsize = iMinblocksize
    cb_dst_bsize = oBlocksize
    cb_dst_minbsize = oMinblocksize

    // Make sure any system calls we made here that failed
    // don't set any user-visible error.
//    errno = 0;
  }
}

// sys/param.h
func roundup(_ x: Int, _ y: Int) -> Int {
  ((((x) % (y)) == 0) ? (x) : ((x) + ((y) - ((x) % (y)))))
}
