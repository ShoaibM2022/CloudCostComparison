<%!
  active_ = "ec2"
  import json
  import six
%>
<%inherit file="base.mako" />
    
    <%block name="meta">
        <title>Amazon EC2 Instance Comparison</title>
        <meta name="description" content="A free and easy-to-use tool for comparing EC2 Instance features and prices."></head>
    </%block>
    

    <div class="row mt-3 me-2" id="menu">
      <div class="col-sm-12 ms-2">

        <div class="btn-group-vertical" id='region-dropdown'>
          <label class="dropdown-label mb-1">Region</label>
          <a class="btn dropdown-toggle btn-primary" data-bs-toggle="dropdown" role="button" href="#">
            <i class="icon-globe icon-white"></i>
            <span class="text">US East (N. Virginia)</span>
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu region-list-dropdown" role="menu">
            <li>
              <input type="text" id="dropdown-search" class="ms-2 mb-2 form-control dropdown-search" placeholder="Search" />
            </li>
            % for region, region_name in regions["main"].items():
            <li>
              <a class="dropdown-item" href="javascript:;" data-region='${region}'>
                <span>${region_name}</span>
                <span class="dropdown-region">${region}</span>
              </a>
            </li>
            % endfor
            <div class="ms-2 mb-2 mt-2">
              <span><strong>Local Zones</strong></span>
            </div>
            % for region, region_name in regions["local_zone"].items():
            <li>
              <a class="dropdown-item" href="javascript:;" data-region='${region}'>
                <span>${region_name}</span>
                <span class="dropdown-region">${region}</span>
              </a>
            </li>
            % endfor
            <div class="ms-2 mb-2 mt-2">
              <span><strong>Wavelength Zones</strong></span>
            </div>
            % for region, region_name in regions["wavelength"].items():
            <li>
              <a class="dropdown-item" href="javascript:;" data-region='${region}'>
                <span>${region_name}</span>
                <span class="dropdown-region">${region}</span>
              </a>
            </li>
            % endfor
          </ul>
        </div>

        <div class="btn-group-vertical d-none d-md-inline-flex" id="pricing-unit-dropdown">
          <label class="dropdown-label mb-1">Pricing Unit</label>
          <a class="btn dropdown-toggle btn-primary" data-bs-toggle="dropdown" role="button" href="#">
            <i class="icon-shopping-cart icon-white"></i>
            <span class="text">Instance</span>
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu" role="menu">
            <li class="active"><a class="dropdown-item" href="javascript:;" pricing-unit="instance">Instance</a></li>
            <li><a class="dropdown-item" href="javascript:;" pricing-unit="vcpu">vCPU</a></li>
            <li><a class="dropdown-item" href="javascript:;" pricing-unit="ecu">ECU</a></li>
            <li><a class="dropdown-item" href="javascript:;" pricing-unit="memory">Memory</a></li>
           </ul>
        </div>

        <div class="btn-group-vertical" id="cost-dropdown">
          <label class="dropdown-label mb-1">Cost</label>
          <a class="btn dropdown-toggle btn-primary" data-bs-toggle="dropdown" role="button" href="#">
            <i class="icon-shopping-cart icon-white"></i>
            <span class="text">Hourly</span>
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu" role="menu">
            <li><a class="dropdown-item" href="javascript:;" duration="secondly">Per Second</a></li>
            <li><a class="dropdown-item" href="javascript:;" duration="minutely">Per Minute</a></li>
            <li class="active"><a class="dropdown-item" href="javascript:;" duration="hourly">Hourly</a></li>
            <li><a class="dropdown-item" href="javascript:;" duration="daily">Daily</a></li>
            <li><a class="dropdown-item" href="javascript:;" duration="weekly">Weekly</a></li>
            <li><a class="dropdown-item" href="javascript:;" duration="monthly">Monthly</a></li>
            <li><a class="dropdown-item" href="javascript:;" duration="annually">Annually</a></li>
          </ul>
        </div>

        <div class="btn-group-vertical d-none d-md-inline-flex" id='reserved-term-dropdown'>
          <label class="dropdown-label mb-1">Reserved</label>
          <a class="btn dropdown-toggle btn-primary" data-bs-toggle="dropdown" role="button" href="#">
            <i class="icon-globe icon-white"></i>
            <span class="text">1-year - No Upfront</span>
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu" role="menu">
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm1Standard.noUpfront'>1-year - No Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm1Standard.partialUpfront'>1-year - Partial Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm1Standard.allUpfront'>1-year - Full Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm3Standard.noUpfront'>3-year - No Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm3Standard.partialUpfront'>3-year - Partial Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm3Standard.allUpfront'>3-year - Full Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm1Convertible.noUpfront'>1-year convertible - No Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm1Convertible.partialUpfront'>1-year convertible - Partial Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm1Convertible.allUpfront'>1-year convertible - Full Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm3Convertible.noUpfront'>3-year convertible - No Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm3Convertible.partialUpfront'>3-year convertible - Partial Upfront</a></li>
            <li><a class="dropdown-item" href="javascript:;" data-reserved-term='yrTerm3Convertible.allUpfront'>3-year convertible - Full Upfront</a></li>
          </ul>
        </div>

        <div class="btn-group-vertical" id="filter-dropdown">
          <!-- blank label maintains spacing -->
          <label class="dropdown-label mb-1">Visible</label>
          <a class="btn dropdown-toggle btn-primary" data-bs-toggle="dropdown" role="button" href="#">
            <i class="icon-filter icon-white"></i>
            Columns
            <span class="caret"></span>
          </a>
          <ul class="dropdown-menu" role="menu">
            <!-- table header elements inserted by js -->
          </ul>
        </div>

        <div class="btn-group-vertical">
          <label class="dropdown-label mb-1"><br></label>
          <button class="btn btn-purple btn-compare"
            data-text-on="End Compare"
            data-text-off="Compare">
            Compare 
          </button>
        </div>

        <div class="btn-group-vertical">
          <label class="dropdown-label mb-1"><br></label>
          <button class="btn btn-primary btn-clear" id="clear">
            Clear Filters
          </button>
        </div>

        <div class="btn-group-vertical float-end m2 p2" id="search">
          <label class="dropdown-label mb-1"><br></label>
          <input id="fullsearch" type="text" class="form-control d-none d-xl-block" placeholder="Search...">
        </div>

        <div class="btn-group-vertical float-end px-2">
          <label class="dropdown-label mb-1"><br></label>
          <div class="btn-primary" id="export"></div>
        </div>

      </div>
    </div>

  <div class="table-responsive overflow-auto wrap-table flex-fill">
    <table cellspacing="0" style="border-bottom: 0 !important; margin-bottom: 0 !important;" id="data" width="100%" class="table">
      <thead>
        <tr>
          <th class="name all" data-priority="1"><div class="d-none d-md-block">Name</div></th>
          <th class="apiname" data-priority="1">API Name</th>
          <th class="memory">Instance Memory</th>
          <th class="computeunits hidden">
            <abbr title="One EC2 Compute Unit provides the equivalent CPU capacity of a 1.0-1.2 GHz 2007 Opteron or 2007 Xeon processor.">Compute Units (ECU)</abbr>
          </th>
          <th class="vcpus">
            <abbr title="Each virtual CPU is a hyperthread of an Intel Xeon core for M3, C4, C3, R3, HS1, G2, I2, and D2">vCPUs</abbr>
          </th>
          <th class="memory-per-vcpu hidden">GiB of Memory per vCPU</th>
          <th class="gpus hidden">GPUs</th>
          <th class="gpu_model hidden">GPU model</th>
          <th class="gpu_memory hidden">GPU memory</th>
          <th class="compute_capability hidden">CUDA Compute Capability</th>
          <th class="fpgas hidden">FPGAs</th>
          <th class="ecu-per-vcpu hidden">ECU per vCPU</th>
          <th class="physical_processor hidden">Physical Processor</th>
          <th class="clock_speed_ghz hidden">Clock Speed(GHz)</th>
          <th class="intel_avx hidden">Intel AVX</th>
          <th class="intel_avx2 hidden">Intel AVX2</th>
          <th class="intel_avx512 hidden">Intel AVX-512</th>
          <th class="intel_turbo hidden">Intel Turbo</th>
          <th class="storage">Instance Storage</th>
          <th class="warmed-up hidden">Instance Storage: already warmed-up</th>
          <th class="trim-support hidden">Instance Storage: SSD TRIM Support</th>
          <th class="architecture hidden">Arch</th>
          <th class="networkperf">Network Performance</th>
          <th class="ebs-baseline-bandwidth hidden">EBS Optimized: Baseline Bandwidth</th>
          <th class="ebs-baseline-throughput hidden">EBS Optimized: Baseline Throughput (128K)</th>
          <th class="ebs-baseline-iops hidden">EBS Optimized: Baseline IOPS (16K)</th>
          <th class="ebs-max-bandwidth hidden">EBS Optimized: Max Bandwidth</th>
          <th class="ebs-throughput hidden">EBS Optimized: Max Throughput (128K)</th>
          <th class="ebs-iops hidden">EBS Optimized: Max IOPS (16K)</th>
          <th class="ebs-as-nvme hidden">
            <abbr title="EBS volumes on these instances will be exposed as NVMe devices (/dev/nvmeXn1)">EBS Exposed as NVMe</abbr>
          </th>
          <th class="maxips hidden">
            <abbr title="Adding additional IPs requires launching the instance in a VPC.">Max IPs</abbr>
          </th>
          <th class="maxenis hidden">Max ENIs</th>
          <th class="enhanced-networking hidden">Enhanced Networking</th>
          <th class="vpc-only hidden">VPC Only</th>
          <th class="ipv6-support hidden">IPv6 Support</th>
          <th class="placement-group-support hidden">Placement Group Support</th>
          <th class="linux-virtualization hidden">Linux Virtualization</th>
          <th class="emr-support hidden">On EMR</th>
          <th class="azs hidden">
            <abbr title="The AZ IDs where these instances are available, which is a unique and consistent identifier for an Availability Zone across AWS accounts.">Availability Zones</abbr>
          </th>

          <th class="cost-ondemand cost-ondemand-linux all" data-priority="1">On Demand</th>
          <th class="cost-reserved cost-reserved-linux">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Linux Reserved cost</abbr>
          </th>
          <th class="cost-spot-min cost-spot-min-linux">
            <abbr title='Minimum spot price for the region, which is specific to one AZ.  Spot prices are different per availabiliy zone.'>Linux Spot Minimum cost</abbr>
          </th>
          <th class="cost-spot-max cost-spot-max-linux hidden">
            <abbr title='30 day historical average spot sprice for the whole region.  Spot prices differ per AZ.  Source: Spot Instance Advisor.'>Linux Spot Average cost</abbr>
          </th>
          <th class="cost-ondemand cost-ondemand-rhel hidden">RHEL On Demand cost</th>
          <th class="cost-reserved cost-reserved-rhel hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>RHEL Reserved cost</abbr>
          </th>
          <th class="cost-spot-min cost-spot-min-rhel hidden">RHEL Spot Minimum cost</th>
          <th class="cost-spot-max cost-spot-max-rhel hidden">RHEL Spot Maximum cost</th>

          <th class="cost-ondemand cost-ondemand-sles hidden">SLES On Demand cost</th>
          <th class="cost-reserved cost-reserved-sles hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>SLES Reserved cost</abbr>
          </th>
          <th class="cost-spot-min cost-spot-min-sles hidden">SLES Spot Minimum cost</th>
          <th class="cost-spot-max cost-spot-max-sles hidden">SLES Spot Maximum cost</th>

          <th class="cost-ondemand cost-ondemand-mswin">Windows On Demand cost</th>
          <th class="cost-reserved cost-reserved-mswin">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Windows Reserved cost</abbr>
          </th>
          <th class="cost-spot-min cost-spot-min-mswin hidden">
            <abbr title='Minimum spot price for the region, which is specific to one AZ.  Spot prices are different per availabiliy zone.'>Windows Spot Minimum cost</abbr>
          </th>
          <th class="cost-spot-max cost-spot-max-mswin hidden">
            <abbr title='Trailing 30 day average spot sprice for the whole region.  Spot prices differ per AZ.  Source: Spot Instance Advisor.'>Windows Spot Average cost</abbr>
          </th>

          <th class="cost-ondemand cost-ondemand-dedicated hidden">Dedicated Host On Demand</th>
          <th class="cost-reserved cost-reserved-dedicated hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Dedicated Host Reserved</abbr>
          </th>

          <th class="cost-ondemand cost-ondemand-mswinSQLWeb hidden">Windows SQL Web On Demand cost</th>
          <th class="cost-reserved cost-reserved-mswinSQLWeb hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Windows SQL Web Reserved cost</abbr>
          </th>
          <th class="cost-ondemand cost-ondemand-mswinSQL hidden">Windows SQL Std On Demand cost</th>
          <th class="cost-reserved cost-reserved-mswinSQL hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Windows SQL Std Reserved cost</abbr>
          </th>
          <th class="cost-ondemand cost-ondemand-mswinSQLEnterprise hidden">Windows SQL Ent On Demand cost</th>
          <th class="cost-reserved cost-reserved-mswinSQLEnterprise hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Windows SQL Ent Reserved cost</abbr>
          </th>
          <th class="cost-ondemand cost-ondemand-linuxSQLWeb hidden">Linux SQL Web On Demand cost</th>
          <th class="cost-reserved cost-reserved-linuxSQLWeb hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Linux SQL Web Reserved cost</abbr>
          </th>
          <th class="cost-ondemand cost-ondemand-linuxSQL hidden">Linux SQL Std On Demand cost</th>
          <th class="cost-reserved cost-reserved-linuxSQL hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Linux SQL Std Reserved cost</abbr>
          </th>
          <th class="cost-ondemand cost-ondemand-linuxSQLEnterprise hidden">Linux SQL Ent On Demand cost</th>
          <th class="cost-reserved cost-reserved-linuxSQLEnterprise hidden">
            <abbr title='Reserved costs are an "effective" hourly rate, calculated by hourly rate + (upfront cost / hours in reserved term).  Actual hourly rates may vary.'>Linux SQL Ent Reserved cost</abbr>
          </th>
          <th class="spot-interrupt-rate hidden">
            <abbr title='The frequency at which Linux spot instances are reclaimed by AWS. Source: Spot Instance Advisor.'>Linux Spot Interrupt Frequency</abbr>
          </th>
          <th class="cost-emr hidden">
            <abbr title="This are the hourly rate EMR costs. Actual costs are EC2 + EMR by hourly rate">EMR cost</abbr>
          </th>
          <th class="generation hidden">Generation</th>
        </tr>
      </thead>

      <tbody>
        % for inst in instances:
          <tr class='instance' id="${inst['instance_type']}">
            <td class="name all"><div class="d-none d-md-block">${inst['pretty_name']}</div></td>
            <td class="apiname"><a href="/aws/ec2/${inst['instance_type']}">${inst['instance_type']}</a></td>
            <td class="memory"><span sort="${inst['memory']}">${inst['memory']} GiB</span></td>
            <td class="computeunits hidden">
              % if inst['ECU'] == 'variable':
                % if inst['base_performance']:
                <span sort="${inst['base_performance']}">
                  <abbr title="For T2 instances, the 100% unit represents a High Frequency Intel Xeon Processors with Turbo up to 3.3GHz.">
                  <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html" target="_blank">Base performance:
                  ${"%g" % (inst['base_performance'] * 100,)}%
                  </a></abbr>
                </span>
                % else:
                <span sort="0"><a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts_micro_instances.html" target="_blank">Burstable</a></span>
                % endif
              % else:
              <span sort="${inst['ECU']}">${"%g" % (inst['ECU'],)} units</span>
              % endif
            </td>
            <td class="vcpus">
              <span sort="${inst['vCPU']}">
                ${inst['vCPU']} vCPUs
                  % if inst['burst_minutes']:
                  <abbr title="Given that a CPU Credit represents the performance of a full CPU core for one minute, the maximum credit balance is converted to CPU burst minutes per day by dividing it by the number of vCPUs.">
                  <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-performance-instances.html" target="_blank">
                  for a
                  ${"%gh %gm" % divmod(inst['burst_minutes'], 60)}
                  burst
                  </a></abbr>
                  % endif
              </span>
            </td>
            <td class="memory-per-vcpu hidden">
              % if inst['memory_per_vcpu'] == 'unknown':
              <span sort="999999">unknown</span>
              % else:
              <span sort="${inst['memory_per_vcpu']}">${"{:.2f}".format(inst['memory_per_vcpu'])} GiB/vCPU</span>
              % endif
            </td>
            <td class="gpus hidden">
              <span sort="${inst['GPU']}">
                ${inst['GPU']}
              </span>
            </td>
            <td class="gpu_model hidden">${inst['GPU_model']}</td>
            <td class="gpu_memory hidden">
              <span sort="${inst['GPU_memory']}">
                ${inst['GPU_memory']} GiB
              </span>
            </td>
            <td class="compute_capability hidden">${inst['compute_capability']}</td>
            <td class="fpga hidden">${inst['FPGA']}</td>
            <td class="ecu-per-vcpu hidden">
              % if inst['ECU'] == 'variable':
              <span sort="0"><a href="http://aws.amazon.com/ec2/instance-types/#burst" target="_blank">Burstable</a></span>
              % elif inst['ECU_per_vcpu'] == 'unknown':
              <span sort="0">unknown</span>
              % else:
              <span sort="${inst['ECU_per_vcpu']}">${"%.4g" % inst['ECU_per_vcpu']} units</span>
              % endif
            </td>
            <td class="physical_processor hidden">${inst['physical_processor'] or 'unknown'}</td>
            <td class="clock_speed_ghz hidden">${inst['clock_speed_ghz'] or 'unknown'}</td>
            <td class="intel_avx hidden">${'Yes' if inst['intel_avx'] else 'unknown'}</td>
            <td class="intel_avx2 hidden">${'Yes' if inst['intel_avx2'] else 'unknown'}</td>
            <td class="intel_avx512 hidden">${'Yes' if inst['intel_avx512'] else 'unknown'}</td>
            <td class="intel_turbo hidden">${'Yes' if inst['intel_turbo'] else 'unknown'}</td>
            <td class="storage">
              <% storage = inst['storage'] %>
              % if not storage:
              <span sort="0">EBS only</span>
              % else:
              <span sort="${storage['devices']*storage['size']}">
                ${storage['devices'] * storage['size']} ${storage['size_unit']}
                % if storage['devices'] > 1:
                (${storage['devices']} * ${storage['size']} ${storage['size_unit']} ${"NVMe " if storage['nvme_ssd'] else ''}${"SSD" if storage['ssd'] else 'HDD'})
                % else:
                ${"NVMe " if storage['nvme_ssd'] else ''}${"SSD" if storage['ssd'] else 'HDD'}
                % endif
                ${"+ 900MB swap" if storage['includes_swap_partition'] else ''}
              </span>
              % endif
            </td>
            <td class="warmed-up hidden">
              % if inst['storage']:
                  ${"No" if inst['storage']['storage_needs_initialization'] else 'Yes'}
              % else:
                  N/A
              % endif
            </td>
            <td class="trim-support hidden">
              % if inst['storage'] and inst['storage']['ssd'] :
                  ${"Yes" if inst['storage']['trim_support'] else 'No'}
              % else:
                  N/A
              % endif
            </td>
            <td class="architecture hidden">
              % if 'i386' in inst['arch']:
              32/64-bit
              % else:
              64-bit
              % endif
            </td>
            <td class="networkperf">
              <span sort="${inst['network_sort']}">
                ${inst['network_performance']}
              </span>
            </td>
            <td class="ebs-baseline-bandwidth hidden">
              % if not inst['ebs_baseline_bandwidth']:
              <span sort="0">N/A</span>
              % else:
              <span sort="${inst['ebs_baseline_bandwidth']}">
                ${inst['ebs_baseline_bandwidth']} Mbps  <!-- Not MB/s! -->
              </span>
              % endif
            </td>
            <td class="ebs-baseline-throughput hidden">
              <span sort="${inst['ebs_baseline_throughput']}">
                ${inst['ebs_baseline_throughput']} MB/s
              </span>
            </td>
            <td class="ebs-baseline-iops hidden">
              <span sort="${inst['ebs_baseline_iops']}">
                ${inst['ebs_baseline_iops']} IOPS
              </span>
            </td>
            <td class="ebs-max-bandwidth hidden">
              % if not inst['ebs_max_bandwidth']:
              <span sort="0">N/A</span>
              % else:
              <span sort="${inst['ebs_max_bandwidth']}">
                ${inst['ebs_max_bandwidth']} Mbps  <!-- Not MB/s! -->
              </span>
              % endif
            </td>
            <td class="ebs-throughput hidden">
              <span sort="${inst['ebs_throughput']}">
                ${inst['ebs_throughput']} MB/s
              </span>
            </td>
            <td class="ebs-iops hidden">
              <span sort="${inst['ebs_iops']}">
                ${inst['ebs_iops']} IOPS
              </span>
            </td>
            <td class="ebs-as-nvme hidden">
              % if inst['ebs_as_nvme']:
                  Yes
              % else:
                  No
              % endif
            </td>
            <td class="maxips hidden">
              % if inst['vpc']:
                <%
                  maxips = inst['vpc']['max_enis'] * inst['vpc']['ips_per_eni']
                %>
                <span sort="${maxips}">
                  ${maxips}
                </span>
              % else:
                <span sort="0">N/A</span>
              % endif
            </td>
            <td class="maxenis hidden">
              % if inst['vpc']:
                <span sort="${inst['vpc']['max_enis']}">${inst['vpc']['max_enis']}</span>
              % else:
                <span sort="0">N/A</span>
              % endif
            </td>
            <td class="enhanced-networking hidden">
              ${'Yes' if inst['enhanced_networking'] else 'No'}
            </td>
            <td class="vpc-only hidden">
              ${'Yes' if inst['vpc_only'] else 'No'}
            </td>
            <td class="ipv6-support hidden">
              ${'Yes' if inst['ipv6_support'] else 'No'}
            </td>
            <td class="placement-group-support hidden">
              ${'Yes' if inst['placement_group_support'] else 'No'}
            </td>
            <td class="linux-virtualization hidden">
              % if inst['linux_virtualization_types']:
              ${', '.join(inst['linux_virtualization_types'])}
              % else:
              Unknown
              % endif
            </td>
            <td class="emr-support hidden">
              ${'Yes' if inst['emr'] else 'No'}
            </td>
            <td class="azs hidden">
              ${', '.join(inst.get('availability_zones', {}).get('us-east-1', []))}
            </td>
            
            % for platform in ['linux', 'rhel', 'sles', 'mswin', 'dedicated', 'mswinSQLWeb', 'mswinSQL', 'mswinSQLEnterprise', 'linuxSQLWeb', 'linuxSQL', 'linuxSQLEnterprise']:
              ## note that the contents in these cost cells are overwritten by the JS change_cost() func, but the initial
              ## data here is used for sorting (and anyone with JS disabled...)
              ## for more info, see https://github.com/powdahound/ec2instances.info/issues/140
              % if platform == 'linux':
                <td class="cost-ondemand cost-ondemand-linux all" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}" data-priority="1">
              % elif platform == 'mswin':
                <td class="cost-ondemand cost-ondemand-mswin" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}" data-priority="1">

              % else:
                <td class="cost-ondemand cost-ondemand-${platform} hidden" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
              % endif

              % if inst['pricing'].get('us-east-1', {}).get(platform, {}).get('ondemand', 'N/A') != "N/A":
                <span sort="${inst['pricing']['us-east-1'][platform]['ondemand']}">
                  $${"{:.4f}".format(float(inst['pricing']['us-east-1'][platform]['ondemand']))} hourly
                </span>
              % else:
                <span sort="999999">unavailable</span>
              % endif
                </td>

              % if platform == 'linux' or platform == 'mswin':
                <td class="cost-reserved cost-reserved-${platform}" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
              % else:
                <td class="cost-reserved cost-reserved-${platform} hidden" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
              % endif

                % if inst['pricing'].get('us-east-1', {}).get(platform, {}).get('reserved', 'N/A') != "N/A" and inst['pricing']['us-east-1'][platform]['reserved'].get('yrTerm1Standard.noUpfront', 'N/A') != "N/A":
                  <span sort="${inst['pricing']['us-east-1'][platform]['reserved']['yrTerm1Standard.noUpfront']}">
                    $${"{:.4f}".format(float(inst['pricing']['us-east-1'][platform]['reserved']['yrTerm1Standard.noUpfront']))} hourly
                  </span>
                % else:
                  <span sort="999999">unavailable</span>
                % endif
              </td>

              % if platform in ['linux', 'rhel', 'sles', 'mswin']:
                % if platform == 'linux':
                  <td class="cost-spot-min cost-spot-min-${platform}" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
                % else:
                  <td class="cost-spot-min cost-spot-min-${platform} hidden" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
                % endif
                  % if inst['pricing'].get('us-east-1', {}).get(platform, {}).get('spot_min', 'N/A') != 'N/A':
                    <%
                        spot_min = inst['pricing']['us-east-1'][platform]['spot_min']
                    %>
                    <span sort="${spot_min}">
                      $${"{:.4f}".format(float(spot_min))} hourly
                    </span>
                  % else:
                    <span sort="999999">unavailable</span>
                  % endif
                </td>

                <td class="cost-spot-max cost-spot-max-${platform} hidden" data-platform="${platform}" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
                  % if platform == 'linux' or platform == 'mswin':
                    <%
                      spot_price = inst['pricing'].get('us-east-1', {}).get(platform, {}).get('spot_avg', 'N/A')
                    %>
                  % else: 
                    <%
                      spot_price = inst['pricing'].get('us-east-1', {}).get(platform, {}).get('spot_max', 'N/A')
                    %>
                  % endif
                  % if spot_price != 'N/A':
                    <span sort="${spot_price}">
                      $${"{:.4f}".format(float(spot_price))} hourly
                    </span>
                  % else:
                    <span sort="999999">unavailable</span>
                  % endif
                </td>
              % endif
            % endfor

            <td class="spot-interrupt-rate hidden" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
              <% intrpt = inst['pricing'].get('us-east-1', {}).get('linux', {}).get('pct_interrupt', 'N/A') %>
              % if intrpt != "N/A":
                <% freq = ["<5%", "5-10%", "10-15%", "15-20%", ">20%"] %>
                <% sort = freq.index(intrpt) %> 
                <span sort="${sort}">${intrpt}</span>
              % else:
                <span sort="9">unavailable</span>
              % endif

            </td>
            <td class="cost-emr cost-emr hidden" data-vcpu="${inst['vCPU']}" data-ecu="${inst['ECU']}" data-memory="${inst['memory']}">
              % if inst['pricing'].get('us-east-1', {}).get("emr", {}):
                <span sort="${inst['pricing']['us-east-1']['emr']['emr']}">
                  $${"{:.4f}".format(float(inst['pricing']['us-east-1']["emr"]['emr']))} hourly
                </span>
              % else:
                <span sort="999999">unavailable</span>
              % endif
            </td>
            <td class="generation hidden">${inst['generation']}</td>
          </tr>
        % endfor
      </tbody>
    </table>

    <%include file="ads-connect.mako"/>

  </div>

  <%block name="header">
    <span>EC2Instances.info - Easy Amazon <b>EC2</b> Instance Comparison</span>
  </%block>