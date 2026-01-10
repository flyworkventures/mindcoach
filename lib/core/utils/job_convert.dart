class JobConvert {
final String value;
  JobConvert(this.value);


Map<String,String> allJobs= {
  "family_assistant": "Aile Asistanı",
  "thought_and_habit_guide": "Düşünce ve Alışkanlık Rehberi",

};



 String call(){
  String jobName = allJobs[value]!;
  return jobName;
}


}
