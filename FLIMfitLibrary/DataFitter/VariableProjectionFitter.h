//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

#pragma once

#include "AbstractFitter.h"
#include "VariableProjector.h"
#include "nnls.h"

#define ANALYTICAL_DERV 0
#define NUMERICAL_DERV  1

class VariableProjectionFitter : public AbstractFitter
{

public:
   VariableProjectionFitter(std::shared_ptr<DecayModel> model, int max_region_size, int weighting, int global_algorithm, int n_thread, std::shared_ptr<ProgressReporter> reporter);
   ~VariableProjectionFitter();

   void FitFcn(int nl, std::vector<double>& alf, int itmax, int* niter, int* ierr);

   void GetLinearParams(); 

private:
   
   int getResidualNonNegative(const double* alf, double *rnorm, double *fjrow, int isel, int thread);

   int prepareJacobianCalculation(const double* alf, double *rnorm, double *fjrow, int thread);
   int getJacobianEntry(const double* alf, double *rnorm, double *fjrow, int row, int thread);

   void calculateWeights(int px, const double* alf, std::vector<double>& wp);

   std::vector<double> w;

   std::vector<VpBuffer> vp_buffer;

   // Buffers used by levmar algorithm
   double *fjac;
   double *fvec;
   double *diag;
   double *qtf;
   double *wa1, *wa2, *wa3, *wa4;
   int    *ipvt;
   
   int n_call;

   int n_jac_group;

   int weighting;
   int iterative_weighting;

   int use_numerical_derv;
   int using_gamma_weighting;

   bool fit_successful = false;

   std::unique_ptr<NonNegativeLeastSquares> nnls;

   friend int VariableProjectionFitterDiffCallback(void *p, int m, int n, const double *x, double *fnorm, int iflag);
   friend int VariableProjectionFitterCallback(void *p, int m, int n, int s, const double *x, double *fnorm, double *fjrow, int iflag, int thread);
};