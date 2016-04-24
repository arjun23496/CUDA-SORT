#include <stdio.h>
#include <time.h>

__device__ void swap(int &a,int &b)
{
	int c;
	c=a;
	a=b;
	b=c;
}	

__device__ int partition(int *array,int l,int u)
{
	int p=array[u-1];
	int j=l-1;

	for(int i=l;i<u-1;i++)
	{
		if(array[i]<p)
		{
			j++;

			swap(array[j],array[i]);			
		}
	}
	j++;
	swap(array[j],array[u-1]);

	return j;
}

__device__ int quickSelect(int *array,int l,int u,int x)
{
	int q=array[l];
	if(l<u)
	{
		q=partition(array,l,u);
		
		if(x<q)
		{
			return quickSelect(array,l,q,x);
		}
		else if(x>q)
		{	
			return quickSelect(array,q+1,u,x);
		}
		else
		{	
			return array[q];	
		}

	}
	return array[q];
}

__global__ void findMedian(int* medians,int* d_in,int n,int N,int k){

	int idx=threadIdx.x;
	int multiplier=ceil((double)n/N);
	int l=multiplier*idx;
	int u=multiplier*(idx+1);
	int m=l+((u-l)/2);

	u=(u>n)?n:u;

	medians[idx]=quickSelect(d_in,l,u,m);

}

void swapHost(int &a,int &b)
{
	int c;
	c=a;
	a=b;
	b=c;
}	

int partitionHost(int *array,int l,int u)
{
	int p=array[u-1];
	int j=l-1;

	for(int i=l;i<u-1;i++)
	{
		if(array[i]<p)
		{
			j++;

			swapHost(array[j],array[i]);			
		}
	}
	j++;
	swapHost(array[j],array[u-1]);

	return j;
}

int quickSelectHost(int *array,int l,int u,int x)
{
	int q=array[l];
	if(l<u)
	{
		q=partitionHost(array,l,u);
		
		if(x<q)
		{
			return quickSelectHost(array,l,q,x);
		}
		else if(x>q)
		{	
			return quickSelectHost(array,q+1,u,x);
		}
		else
		{	
			return array[q];	
		}

	}
	return array[q];
}

int main(){

	const int ARRAY_SIZE_INPUT=100000;
	const int ARRAY_BYTES_INPUT= ARRAY_SIZE_INPUT*sizeof(int);
	const int NUMBER_OF_PROCESSORS=1000;
	const int MEDIAN_BYTES=NUMBER_OF_PROCESSORS*sizeof(int);
	int k=997;

	int ARRAY_SIZE=ARRAY_SIZE_INPUT;
	int ARRAY_BYTES=ARRAY_BYTES_INPUT;
	int L[ARRAY_SIZE];
	int E[ARRAY_SIZE];
	int G[ARRAY_SIZE];
	int result=0;

	//generate input array
	int array_in[ARRAY_SIZE];
	int initial_array[ARRAY_SIZE];
	
	srand(time(NULL));

	//Array of random integers TODO: srand()
	for(int i=0;i<ARRAY_SIZE;i++)
	{
		array_in[i]=rand()%10000;
		initial_array[i]=array_in[i];
	}

	printf("Input-------------------------------------------\n");
	// Array of random numbers
	for(int i=0;i<ARRAY_SIZE;i++)
	{
		printf("%d ",array_in[i]);
	}
	printf(" k value %d\n",k );
	printf("\n");

	while(true)
	{

		if(ARRAY_SIZE<NUMBER_OF_PROCESSORS)
		{
			result=quickSelectHost(array_in,0,ARRAY_SIZE,k);
			break;
		}

		//cuda variables
		int *d_in;
		int *medians;

		//host medians
		int host_medians[NUMBER_OF_PROCESSORS];
		int device_array[ARRAY_SIZE];

		cudaMalloc((void**)&d_in,ARRAY_BYTES);
		cudaMalloc((void**)&medians,MEDIAN_BYTES);

		cudaMemcpy(d_in,array_in,ARRAY_BYTES,cudaMemcpyHostToDevice);

		findMedian<<<1,NUMBER_OF_PROCESSORS>>>(medians,d_in,ARRAY_SIZE,NUMBER_OF_PROCESSORS,k);

		cudaMemcpy(host_medians,medians,MEDIAN_BYTES,cudaMemcpyDeviceToHost);
		cudaMemcpy(device_array,d_in,ARRAY_BYTES,cudaMemcpyDeviceToHost);

		printf("Medians------------------------------------------------------------\n");

		for(int i=0;i<NUMBER_OF_PROCESSORS;i++)
		{
			printf("%d\n",host_medians[i]);
		}

	printf("\n");
	printf("device array------------------------------------------------------------\n");

	for(int i=0;i<ARRAY_SIZE;i++)
	{
		printf("%d ",device_array[i]);
	}


		printf("\nMedian of medians------------------------------------------------------------\n");

		int medianOfMedians=quickSelectHost(host_medians,0,NUMBER_OF_PROCESSORS,NUMBER_OF_PROCESSORS/2);	

		printf("\n%d\n",medianOfMedians);


		//Clasification

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

		cudaFree(d_in);
		cudaFree(medians);
	}

	printf("\nInitial Input-------------------------------------------\n");
	// Array of random numbers
	for(int i=0;i<ARRAY_SIZE_INPUT;i++)
	{
		printf("%d ",initial_array[i]);
	}
	printf(" k value %d\n",k );
	printf("\n");

	printf("Result is %d\n",result);	

	return 0;

}