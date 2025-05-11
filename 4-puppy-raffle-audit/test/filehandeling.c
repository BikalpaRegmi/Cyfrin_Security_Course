#include<stdio.h>
#include<string.h>

struct Student{
char name[20];
int age ;
char address[30];
int cellNo;
} ;

int main()
{
struct Student std[3],s1 ;

FILE *f;
f=fopen("student.txt","w");

if(f==NULL){
return 1;
}

for(int i=0;i<3;i++)
{
puts("Plz enter ur name");
gets(std[i].name);

printf("Plz enter ur age");
scanf("%d",&std[i].age);

puts("Plz enter ur address");
gets(std[i].address);

printf("Plz enter ur cell number");
scanf("%d",&std[i].cellNo);
fflush(stdin);

fprintf(f,"%s %d %s %d",std[i].name,std[i].age,std[i].address,std[i].cellNo);
}

fclose(f);

f=fopen("student.txt","r");

if(f==NULL){
return 1;
}

while(fscanf(f,"%s %d %s %d",s1.name,&s1.age,s1.address,&s1.cellNo)!=EOF){

if(strcmp("Pokhara",s1.address)==0){
printf("%s %d %s %d",s1.name,s1.age,s1.address,s1.cellNo);
}
}

fclose(f);
}