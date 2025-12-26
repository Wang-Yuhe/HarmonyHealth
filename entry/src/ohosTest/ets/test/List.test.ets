import abilityTest from './Ability.test';
import systemTest from './SystemTest.test';
import localUnitTest from './LocalUnit.test';
import performanceTest from './Performance.test';
import stabilityTest from './Stability.test';
import exceptionHandlingTest from './ExceptionHandling.test';

export default function testsuite() {
  abilityTest();
  systemTest();
  localUnitTest();
  performanceTest();
  stabilityTest();
  exceptionHandlingTest();
}