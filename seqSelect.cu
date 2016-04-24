#include <stdio.h>
#include <stdlib.h>
#include <time.h>

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

int cmpfunc (const void * a, const void * b)
{
   return ( *(int*)a - *(int*)b );
}


int main(){

	const int ARRAY_SIZE_INPUT=100000;
	// const int ARRAY_BYTES_INPUT= ARRAY_SIZE_INPUT*sizeof(int);
	int k=5000;

	int ARRAY_SIZE=ARRAY_SIZE_INPUT;
	int result=0;

	//generate input array
	int array_in[ARRAY_SIZE];
	
	// srand(time(NULL));

	//Array of random integers TODO: srand()
	for(int i=0;i<ARRAY_SIZE;i++)
	{
		array_in[i]=rand()%10000;
	}

	printf("Input-------------------------------------------\n");
	// Array of random numbers
	for(int i=0;i<ARRAY_SIZE;i++)
	{
		printf("%d ",array_in[i]);
	}
	printf(" k value %d\n",k );
	printf("\n");

	// result=quickSelectHost(array_in,0,ARRAY_SIZE,k);

	qsort(array_in,ARRAY_SIZE,sizeof(int),cmpfunc);

	result=array_in[k];

	printf(" result is := %d\n",result);

	return 0;

}