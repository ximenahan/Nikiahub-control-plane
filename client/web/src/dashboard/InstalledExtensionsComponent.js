/*
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

import React from 'react'
import { Col, Card, CardBody } from 'reactstrap'

export default function InstalledExtensionsComponent(props) {
  return (
    <Col xs={1} md={6} lg={6}>
      <Card className="pb-3 bg-white">
        <CardBody className="pb-0">
          <h4>AWS Saas Boost Modules</h4>
          <dl className="row">
            <dt className="col-sm-1 font-xl">
              <i className="icon icon-check text-success"></i>
            </dt>
            <dd className="col-sm-11 font-xl">Billing</dd>
            <dt className="col-sm-1 font-xl">
              <i className="icon icon-close text-danger"></i>
            </dt>
            <dd className="col-sm-11 font-xl">Metrics</dd>
          </dl>
        </CardBody>
      </Card>
    </Col>
  )
}
