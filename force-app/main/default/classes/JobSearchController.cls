public with sharing class JobSearchController {
  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> searchJobs(
    String keywords,
    String location,
    List<String> workTypes
  ) {
    // Return dummy data to test LWC functionality and pagination
    List<Map<String, Object>> allJobs = new List<Map<String, Object>>();

    Map<String, Object> job1 = new Map<String, Object>();
    job1.put('id', '1');
    job1.put('title', 'Senior Software Developer');
    job1.put('salary', '$95,000 - $120,000');
    job1.put('company', 'TechCorp Toronto');
    job1.put('location', 'Toronto');
    job1.put('workType', 'remote');
    job1.put('source', 'LinkedIn');
    allJobs.add(job1);

    Map<String, Object> job2 = new Map<String, Object>();
    job2.put('id', '2');
    job2.put('title', 'Frontend Developer');
    job2.put('salary', '$75,000 - $95,000');
    job2.put('company', 'Digital Solutions Inc');
    job2.put('location', 'Toronto');
    job2.put('workType', 'remote');
    job2.put('source', 'Indeed');
    allJobs.add(job2);

    Map<String, Object> job3 = new Map<String, Object>();
    job3.put('id', '3');
    job3.put('title', 'Full Stack Developer');
    job3.put('salary', '$85,000 - $110,000');
    job3.put('company', 'Innovation Labs');
    job3.put('location', 'Toronto');
    job3.put('workType', 'remote');
    job3.put('source', 'Company Website');
    allJobs.add(job3);

    Map<String, Object> job4 = new Map<String, Object>();
    job4.put('id', '4');
    job4.put('title', 'Backend Developer');
    job4.put('salary', '$80,000 - $105,000');
    job4.put('company', 'CloudTech Toronto');
    job4.put('location', 'Toronto');
    job4.put('workType', 'remote');
    job4.put('source', 'Glassdoor');
    allJobs.add(job4);

    Map<String, Object> job5 = new Map<String, Object>();
    job5.put('id', '5');
    job5.put('title', 'Python Developer');
    job5.put('salary', '$78,000 - $98,000');
    job5.put('company', 'DataFlow Systems');
    job5.put('location', 'Toronto');
    job5.put('workType', 'remote');
    job5.put('source', 'ZipRecruiter');
    allJobs.add(job5);

    Map<String, Object> job6 = new Map<String, Object>();
    job6.put('id', '6');
    job6.put('title', 'Java Developer');
    job6.put('salary', '$82,000 - $108,000');
    job6.put('company', 'Enterprise Solutions');
    job6.put('location', 'Toronto');
    job6.put('workType', 'onsite');
    job6.put('source', 'Monster');
    allJobs.add(job6);

    Map<String, Object> job7 = new Map<String, Object>();
    job7.put('id', '7');
    job7.put('title', 'React Developer');
    job7.put('salary', '$74,000 - $92,000');
    job7.put('company', 'StartupTO');
    job7.put('location', 'Toronto');
    job7.put('workType', 'remote');
    job7.put('source', 'AngelList');
    allJobs.add(job7);

    Map<String, Object> job8 = new Map<String, Object>();
    job8.put('id', '8');
    job8.put('title', 'Node.js Developer');
    job8.put('salary', '$76,000 - $96,000');
    job8.put('company', 'WebTech Toronto');
    job8.put('location', 'Toronto');
    job8.put('workType', 'remote');
    job8.put('source', 'Stack Overflow Jobs');
    allJobs.add(job8);

    Map<String, Object> job9 = new Map<String, Object>();
    job9.put('id', '9');
    job9.put('title', 'Mobile Developer');
    job9.put('salary', '$79,000 - $102,000');
    job9.put('company', 'AppCraft Studios');
    job9.put('location', 'Toronto');
    job9.put('workType', 'remote');
    job9.put('source', 'Dice');
    allJobs.add(job9);

    Map<String, Object> job10 = new Map<String, Object>();
    job10.put('id', '10');
    job10.put('title', 'DevOps Developer');
    job10.put('salary', '$88,000 - $115,000');
    job10.put('company', 'Infrastructure Pro TO');
    job10.put('location', 'Toronto');
    job10.put('workType', 'hybrid');
    job10.put('source', 'CyberSeek');
    allJobs.add(job10);

    Map<String, Object> job11 = new Map<String, Object>();
    job11.put('id', '11');
    job11.put('title', 'Angular Developer');
    job11.put('salary', '$73,000 - $91,000');
    job11.put('company', 'ModernWeb Inc');
    job11.put('location', 'Toronto');
    job11.put('workType', 'remote');
    job11.put('source', 'LinkedIn');
    allJobs.add(job11);

    Map<String, Object> job12 = new Map<String, Object>();
    job12.put('id', '12');
    job12.put('title', 'Vue.js Developer');
    job12.put('salary', '$72,000 - $89,000');
    job12.put('company', 'Progressive Apps');
    job12.put('location', 'Toronto');
    job12.put('workType', 'remote');
    job12.put('source', 'Indeed');
    allJobs.add(job12);

    Map<String, Object> job13 = new Map<String, Object>();
    job13.put('id', '13');
    job13.put('title', 'PHP Developer');
    job13.put('salary', '$65,000 - $83,000');
    job13.put('company', 'LegacyTech Toronto');
    job13.put('location', 'Toronto');
    job13.put('workType', 'onsite');
    job13.put('source', 'FlexJobs');
    allJobs.add(job13);

    Map<String, Object> job14 = new Map<String, Object>();
    job14.put('id', '14');
    job14.put('title', 'C# Developer');
    job14.put('salary', '$84,000 - $112,000');
    job14.put('company', 'Microsoft Partners TO');
    job14.put('location', 'Toronto');
    job14.put('workType', 'hybrid');
    job14.put('source', 'Glassdoor');
    allJobs.add(job14);

    Map<String, Object> job15 = new Map<String, Object>();
    job15.put('id', '15');
    job15.put('title', 'Go Developer');
    job15.put('salary', '$87,000 - $114,000');
    job15.put('company', 'CloudNative Systems');
    job15.put('location', 'Toronto');
    job15.put('workType', 'remote');
    job15.put('source', 'Remote.co');
    allJobs.add(job15);

    Map<String, Object> job16 = new Map<String, Object>();
    job16.put('id', '16');
    job16.put('title', 'Rust Developer');
    job16.put('salary', '$92,000 - $125,000');
    job16.put('company', 'SystemLevelTO');
    job16.put('location', 'Toronto');
    job16.put('workType', 'remote');
    job16.put('source', 'We Work Remotely');
    allJobs.add(job16);

    Map<String, Object> job17 = new Map<String, Object>();
    job17.put('id', '17');
    job17.put('title', 'Swift Developer');
    job17.put('salary', '$81,000 - $106,000');
    job17.put('company', 'iOS Experts Toronto');
    job17.put('location', 'Toronto');
    job17.put('workType', 'remote');
    job17.put('source', 'AngelList');
    allJobs.add(job17);

    Map<String, Object> job18 = new Map<String, Object>();
    job18.put('id', '18');
    job18.put('title', 'Kotlin Developer');
    job18.put('salary', '$83,000 - $109,000');
    job18.put('company', 'Android Pro TO');
    job18.put('location', 'Toronto');
    job18.put('workType', 'remote');
    job18.put('source', 'LinkedIn');
    allJobs.add(job18);

    Map<String, Object> job19 = new Map<String, Object>();
    job19.put('id', '19');
    job19.put('title', 'Ruby Developer');
    job19.put('salary', '$77,000 - $99,000');
    job19.put('company', 'RailsTO');
    job19.put('location', 'Toronto');
    job19.put('workType', 'remote');
    job19.put('source', 'RubyNow');
    allJobs.add(job19);

    Map<String, Object> job20 = new Map<String, Object>();
    job20.put('id', '20');
    job20.put('title', 'Scala Developer');
    job20.put('salary', '$89,000 - $118,000');
    job20.put('company', 'FunctionalTO');
    job20.put('location', 'Toronto');
    job20.put('workType', 'onsite');
    job20.put('source', 'Indeed');
    allJobs.add(job20);

    Map<String, Object> job21 = new Map<String, Object>();
    job21.put('id', '21');
    job21.put('title', 'TypeScript Developer');
    job21.put('salary', '$75,000 - $94,000');
    job21.put('company', 'StronglyTyped Inc');
    job21.put('location', 'Toronto');
    job21.put('workType', 'remote');
    job21.put('source', 'Stack Overflow Jobs');
    allJobs.add(job21);

    Map<String, Object> job22 = new Map<String, Object>();
    job22.put('id', '22');
    job22.put('title', 'Ember.js Developer');
    job22.put('salary', '$70,000 - $87,000');
    job22.put('company', 'AmberTech Toronto');
    job22.put('location', 'Toronto');
    job22.put('workType', 'remote');
    job22.put('source', 'Dice');
    allJobs.add(job22);

    Map<String, Object> job23 = new Map<String, Object>();
    job23.put('id', '23');
    job23.put('title', 'Svelte Developer');
    job23.put('salary', '$71,000 - $88,000');
    job23.put('company', 'ModernFrameworks TO');
    job23.put('location', 'Toronto');
    job23.put('workType', 'remote');
    job23.put('source', 'Remote OK');
    allJobs.add(job23);

    Map<String, Object> job24 = new Map<String, Object>();
    job24.put('id', '24');
    job24.put('title', 'Flutter Developer');
    job24.put('salary', '$78,000 - $101,000');
    job24.put('company', 'CrossPlatform Toronto');
    job24.put('location', 'Toronto');
    job24.put('workType', 'remote');
    job24.put('source', 'FlutterJobs');
    allJobs.add(job24);

    Map<String, Object> job25 = new Map<String, Object>();
    job25.put('id', '25');
    job25.put('title', 'React Native Developer');
    job25.put('salary', '$76,000 - $98,000');
    job25.put('company', 'MobileFirst TO');
    job25.put('location', 'Toronto');
    job25.put('workType', 'hybrid');
    job25.put('source', 'Glassdoor');
    allJobs.add(job25);

    // Add some jobs in different locations for testing
    Map<String, Object> job26 = new Map<String, Object>();
    job26.put('id', '26');
    job26.put('title', 'Software Engineer');
    job26.put('salary', '$90,000 - $115,000');
    job26.put('company', 'Vancouver Tech');
    job26.put('location', 'Vancouver');
    job26.put('workType', 'remote');
    job26.put('source', 'LinkedIn');
    allJobs.add(job26);

    Map<String, Object> job27 = new Map<String, Object>();
    job27.put('id', '27');
    job27.put('title', 'Full Stack Engineer');
    job27.put('salary', '$85,000 - $110,000');
    job27.put('company', 'Montreal Solutions');
    job27.put('location', 'Montreal');
    job27.put('workType', 'hybrid');
    job27.put('source', 'Indeed');
    allJobs.add(job27);

    // Filter the jobs based on search parameters
    List<Map<String, Object>> filteredJobs = new List<Map<String, Object>>();

    for (Map<String, Object> job : allJobs) {
      Boolean includeJob = true;

      // Filter by keywords (search in title)
      if (String.isNotBlank(keywords)) {
        String jobTitle = (String) job.get('title');
        if (
          jobTitle == null ||
          !jobTitle.toLowerCase().contains(keywords.toLowerCase())
        ) {
          includeJob = false;
        }
      }

      // Filter by location
      if (String.isNotBlank(location)) {
        String jobLocation = (String) job.get('location');
        if (
          jobLocation == null ||
          !jobLocation.toLowerCase().contains(location.toLowerCase())
        ) {
          includeJob = false;
        }
      }

      // Filter by work types
      if (workTypes != null && !workTypes.isEmpty()) {
        String jobWorkType = (String) job.get('workType');
        if (jobWorkType == null || !workTypes.contains(jobWorkType)) {
          includeJob = false;
        }
      }

      if (includeJob) {
        filteredJobs.add(job);
      }
    }

    return filteredJobs;
  }
}
