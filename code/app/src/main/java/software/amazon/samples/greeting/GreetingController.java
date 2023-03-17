package software.amazon.samples.greeting;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

/**
 * @author MaheshR
 */
@RestController
public class GreetingController {

    @RequestMapping("/hello")
    public String sayHello() {
        return "Hello from AWS ProServe version1";
    }
   
}
