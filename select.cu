#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <thrust/sort.h>
#include <thrust/execution_policy.h>
// #include <curand_kernel.h>

__device__ int quickSelect(int* array,int l,int u,int index)
{
	int n=u-l;
	int l1=l+1;
	int u1=u-1;
	int i=0;
	int pivot=l;

	if(n==1)
	{
		return array[l];
		// return l;
	}

	while(l1<u1&&i<1000)
	{
		i++;

		if(array[l1]>array[pivot] && array[u1]<array[pivot])
		{
			//swap
			array[l1]+=array[u1];
			array[u1]=array[l1]-array[u1];
			array[l1]=array[l1]-array[u1];
			l1++;		
		}

		if(array[l1]<=array[pivot])
		{
			l1++;
		}
		
		if(array[u1]>array[pivot])
		{
			u1--;
		}
	}

	int pivotEle=array[pivot];
	int pivotPos=l;

	// return 0;

	for(i=l+1;pivotEle>=array[i]&&i<u;i++)
	{
		array[i-1]=array[i];
	}

	array[i-1]=pivotEle;
	
	pivotPos=i-1;
	
	if(pivotPos==index)
	{
		return array[pivotPos];
		// return 555;
	}

	int e;

	if(pivotPos>index)
	{
		e=quickSelect(array,l,pivotPos,index);
		// e=22;
		return e;
	}
	else
	{
		e=quickSelect(array,pivotPos+1,u,index);
		// e=11;
		return e;
	}
}

__global__ void findMedian(int* medians,int* d_in,int n,int N){

	int multiplier=ceil((double)n/N);
	int idx=threadIdx.x;
	int l=idx*multiplier;
	int u=(idx+1)*multiplier;
	int m=l;

	u=(u>n)?n:u;
	m=l+((u-l)/2);

	// medians[idx]=quickSelect(d_in,l,u,m);
	thrust::sort(thrust::seq, d_in+l, d_in+u);
	medians[idx]=d_in[m];
}

int quickSelectHost(int* array,int l,int u,int index)
{
	int n=u-l;
	int l1=l+1;
	int u1=u-1;
	int i=0;
	int pivot=l;

	if(n<=1)
	{
		return array[l];
		// return l;
	}

	while(l1<u1&&i<1000)
	{
		i++;

		if(array[l1]>array[pivot] && array[u1]<array[pivot])
		{
			//swap
			array[l1]+=array[u1];
			array[u1]=array[l1]-array[u1];
			array[l1]=array[l1]-array[u1];
			l1++;		
		}

		if(array[l1]<=array[pivot])
		{
			l1++;
		}
		
		if(array[u1]>array[pivot])
		{
			u1--;
		}
	}

	int pivotEle=array[pivot];
	int pivotPos=l;

	// return 0;

	for(i=l+1;pivotEle>=array[i]&&i<u;i++)
	{
		array[i-1]=array[i];
	}

	array[i-1]=pivotEle;
	
	pivotPos=i-1;
	
	if(pivotPos==index)
	{
		return array[pivotPos];
		// return 555;
	}

	int e;

	if(pivotPos>index)
	{
		e=quickSelectHost(array,l,pivotPos,index);
		// e=22;
		return e;
	}
	else
	{
		e=quickSelectHost(array,pivotPos+1,u,index);
		// e=11;
		return e;
	}
}

int cmpfunc (const void * a, const void * b)
{
   return ( *(int*)a - *(int*)b );
}

int main(){

	const int ARRAY_SIZE_INPUT=13;
	const int ARRAY_BYTES_INPUT = ARRAY_SIZE_INPUT*sizeof(int);
	const int NUMBER_OF_PROCESSORS=10;
	int k=7;

	int ARRAY_SIZE=ARRAY_SIZE_INPUT;
	int ARRAY_BYTES=ARRAY_BYTES_INPUT;
	int MEDIAN_BYTES=NUMBER_OF_PROCESSORS*sizeof(int);	
	// int array_in[ARRAY_SIZE];
	// int array_in_copy[ARRAY_SIZE];
	int medianOfMedians=0;
	int L[ARRAY_SIZE];
	int E[ARRAY_SIZE];
	int G[ARRAY_SIZE];
	int result=0;

	//Cuda pointers
	int *d_in=NULL;
	int *medians=NULL;
	
	//Random number seed
	srand(time(NULL));

	int array_in[]={4, 2, 6, 4 ,4, 2, 10, 13, 0, 13, 4, 13, 9};

	// Array of random numbers
	// for(int i=0;i<ARRAY_SIZE;i++)
	// {
	// 	array_in[i]=rand()%20;
	// 	// array_in_copy[i]=array_in[i];
	// }

	printf("\n");

	while(true)
	{
		printf("---------------------------Ieration ------------------------------------");
		printf("\n");
		for(int i=0;i<ARRAY_SIZE;i++)
		{
			printf("%d ",array_in[i]);
			// array_in_copy[i]=array_in[i];
		}
		printf("\n");
		printf("k value is %d \n",k);
		printf("\n");		

		if(ARRAY_SIZE<NUMBER_OF_PROCESSORS)
		{
			qsort(array_in, ARRAY_SIZE, sizeof(int), cmpfunc);
			result=array_in[k];
			break;
		}

		int host_median[NUMBER_OF_PROCESSORS];

		//Allocate cuda device memory
		cudaMalloc((void**)&d_in,ARRAY_BYTES);
		cudaMalloc((void**)&medians,MEDIAN_BYTES);
		
		//Copy input array to device
		cudaMemcpy(d_in,array_in,ARRAY_BYTES,cudaMemcpyHostToDevice);

		//Find Medians
		findMedian<<<1,NUMBER_OF_PROCESSORS>>>(medians,d_in,ARRAY_SIZE,NUMBER_OF_PROCESSORS);

		cudaMemcpy(host_median,medians,MEDIAN_BYTES,cudaMemcpyDeviceToHost);

		printf("---------------------Medians-----------------------------------\n");

		for(int i=0;i<NUMBER_OF_PROCESSORS;i++)
		{
			printf("%d\n",host_median[i]);
		}

		printf("---------------------Median of medians-----------------------------------\n");

		medianOfMedians=quickSelectHost(host_median,0,NUMBER_OF_PROCESSORS,NUMBER_OF_PROCESSORS/2);

		printf("%d\n",medianOfMedians);

		//Classification

		int lctr=0;
		int ectr=0;
		int gctr=0;

		for(int i=0;i<ARRAY_SIZE;i++)
		{
			if(array_in[i]<medianOfMedians)
			{
				L[lctr]=array_in[i];
				lctr++;
			}
			else
			{
				if(array_in[i]>medianOfMedians)
				{
					G[gctr]=array_in[i];
					gctr++;
				}
				else
				{
					E[ectr]=array_in[i];
					ectr++;
				}
			}
		}

		printf("\n");
		printf("Lesser........................................................");
		printf("\n");

		for(int i=0;i<lctr;i++)
		{
			printf("%d ",L[i]);
		}


		printf("\n");
		printf("Equal........................................................");
		printf("\n");

		for(int i=0;i<ectr;i++)
		{
			printf("%d ",E[i]);
		}


		printf("\n");
		printf("Greater........................................................");
		printf("\n");

		for(int i=0;i<gctr;i++)
		{
			printf("%d ",G[i]);
		}
		printf("\n");

		// Check for completion
		// int u=ARRAY_SIZE;
		if(lctr>=k)
		{
			for(int i=0;i<lctr;i++)
			{
				array_in[i]=L[i];
				ARRAY_SIZE=lctr;
				ARRAY_BYTES=ARRAY_SIZE*sizeof(int);
			}
		}
		else 
		{
			if(lctr+ectr>=k)
			{
				// l=lctr;
				// u=lctr;
				result=E[0];
				break;
			}
			else
			{
				k=k-(lctr+ectr);					
				for(int i=0;i<gctr;i++)
				{
					array_in[i]=G[i];
					ARRAY_SIZE=gctr;
					ARRAY_BYTES=ARRAY_SIZE*sizeof(int);
				}
			}
		}


		//Free Cuda memory
		cudaFree(d_in);
		cudaFree(medians);
	}

	printf("Result is %d \n",result );

	return 0;

}