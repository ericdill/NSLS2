"""
Histogram

General purpose histogram classes.
"""

cimport cython
import numpy as np
cimport numpy as np
from ..utils import bin_edges_to_centers

ctypedef fused hnumtype:
    np.int_t
    np.float_t

ctypedef fused wnumtype:
    np.int_t
    np.float_t


cdef void* _getarrayptr(np.ndarray a):
    return <void*> a.data


class Histogram:
    def __init__(self, binlowhigh, *args):
        """

        Parameters
        ----------
        binlowhigh : iterable
            nbin, low, high = binlowhigh
            nbin is the number of bins
            low is the left most edge
            high is the right most edge
        args : iterable
            Extra instances of binlowhigh that correspond to extra dimensions
            in the Histogram

        Notes
        -----
        The right most bin is half open
        """
        if args:
            raise NotImplementedError(
                "This class does not yet support higher dimensional histograms than 1D"
            )
        bin, low, high = binlowhigh
        self.nbins = [bin]
        self.lows = [low]
        self.highs = [high]
        self._values = np.zeros(self.nbins, dtype=float)
        self.ndims = len(self.nbins)
        self.binsizes = [(high - low) / nbins for high, low, nbins
                         in zip(self.highs, self.lows, self.nbins)]
        return


    def reset(self):
        """Fill the histogram array with 0
        """
        self._values.fill(0)

    def fill(self, *coords, weights=1):
        """

        Parameters
        ----------
        coords : iterable of numpy arrays
            The length of coords is equivalent to the dimensionality of
            the histogram.
        weights

        Returns
        -------

        """
        # check our arguments
        if len(coords) != self.ndims:
            emsg = "Incorrect number of arguments.  Received {} expected {}."
            raise ValueError(emsg.format(len(coords), self.ndims))

        weights = np.asarray(weights).reshape(-1)

        nexpected = len(coords[0])
        for x in coords:
            if len(x) != nexpected:
                emsg = "Coordinate arrays must have the same length."
                raise ValueError(emsg)
        if len(weights) != 1 and len(weights) != nexpected:
            emsg = "Weights must be scalar or have the same length as coordinates."
            raise ValueError(emsg)

        if len(coords) == 1:
            # compute a 1D histogram
            self._fill1d(coords[0], weights)
        else:
            # do the generalized ND histogram
            raise NotImplementedError()
        return


    def _fillnd(self, coords, np.ndarray[wnumtype, ndim=1] weight,
            np.ndarray[hnumtype, ndim=1] dummy):
        cdef hnumtype* pxa[10]
        for i, x in enumerate(coords):
            pxa[i] = <hnumtype*> _getarrayptr(x)
        cdef np.ndarray[np.float_t, ndim=1] data = self.values
        '''
        cdef float [:] lows = self.lows
        cdef float high = self.highs[0]
        cdef float binsize = self.binsizes[0]
        cdef int i
        cdef int xlen = len(xval)
        cdef np.float_t* pdata = <np.float_t*> data.data
        cdef hnumtype* px = <hnumtype*> xval.data
        cdef wnumtype* pw = <wnumtype*> weight.data
        if weight.size == 1:
            for i in range(xlen):
                fillonecy(px[i], pw[0], pdata, low, high, binsize)
        else:
            for i in range(xlen):
                fillonecy(px[i], pw[i], pdata, low, high, binsize)
        '''
        return

    def _fill1d(self, np.ndarray[hnumtype, ndim=1] xval,
                np.ndarray[wnumtype, ndim=1] weight):
        cdef np.ndarray[np.float_t, ndim=1] data = self.values
        cdef float low = self.lows[0]
        cdef float high = self.highs[0]
        cdef float binsize = self.binsizes[0]
        cdef int i
        cdef int xlen = len(xval)
        cdef np.float_t* pdata = <np.float_t*> data.data
        cdef hnumtype* px = <hnumtype*> xval.data
        cdef wnumtype* pw = <wnumtype*> weight.data
        if weight.size == 1:
            for i in range(xlen):
                fillonecy(px[i], pw[0], pdata, low, high, binsize)
        else:
            for i in range(xlen):
                fillonecy(px[i], pw[i], pdata, low, high, binsize)
        return

    @property
    def values(self):
        return self._values

    @property
    def edges(self):
        return [np.linspace(low, high, nbin+1) for nbin, low, high
                in zip(self.nbins, self.lows, self.highs)]

    @property
    def centers(self):
        return [bin_edges_to_centers(edge) for edge in self.edges]


cdef void fillonecy(hnumtype xval, wnumtype weight,
        np.float_t* pdata,
        float low, float high, float binsize):
    if not (low <= xval < high):
        return
    cdef int iidx
    iidx = int((xval - low) / binsize)
    pdata[iidx] += weight
    return



#TODO implement ND histogram
#TODO function interface
#TODO generator interface
#TODO docs!
#TODO examples
#TODO Can we support ND histogram for mixed coordinate types?
