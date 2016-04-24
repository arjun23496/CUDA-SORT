#include <stdio.h>
#include <time.h>

__global__ void square(float* d_out,float* d_in){
	int idx= threadIdx.x;
	float f= d_in[idx];
	d_out[idx]=f*f;
	// d_out[idx]=idx;
}

int main(){
	const int ARRAY_SIZE=64;
	const int ARRAY_BYTES= ARRAY_SIZE*sizeof(float);

	//generate input array
	float h_in[ARRAY_SIZE];
	for(int i=0;i<ARRAY_SIZE;i++)
	{
		h_in[i]=float(i);
	}
	float h_out[ARRAY_SIZE];

	float *d_in;
	float *d_out;

	cudaMalloc((void**)&d_in,ARRAY_BYTES);
	cudaMalloc((void**)&d_out,ARRAY_BYTES);

	cudaMemcpy(d_in,h_in,ARRAY_BYTES,cudaMemcpyHostToDevice);

	square<<<1,ARRAY_SIZE>>>(d_out,d_in);

	cudaMemcpy(h_out,d_out,ARRAY_BYTES,cudaMemcpyDeviceToHost);

	printf("\n");

	for(int i=0;i<ARRAY_SIZE;i++)
	{
		printf("%f\n",h_out[i]);
	}

	cudaFree(d_in);
	cudaFree(d_out);

	return 0;

}
