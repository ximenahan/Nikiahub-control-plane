/**
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.amazon.aws.partners.saasfactory.saasboost;

import com.amazonaws.services.lambda.runtime.events.APIGatewayProxyResponseEvent;

import java.net.URISyntaxException;
import java.util.HashMap;
import java.util.Map;

public class LimitTest {

    public static void main(String args[]) throws URISyntaxException {
/*
        LimitServiceDAL dal = new LimitServiceDAL();
        dal.handleRequest();
*/
        QuotasService service = new QuotasService();
        Map<String, Object> event = new HashMap<>();
        APIGatewayProxyResponseEvent responseBody = service.checkQuotas(event, null);
        System.out.println("body: " + responseBody.getBody());
        Map<String, Object> valMap = Utils.fromJson(responseBody.getBody(), HashMap.class);
        Boolean passed = (Boolean) valMap.get("passed");
        System.out.println("passed " + passed);
        String message = (String) valMap.get("message");
    }
}
