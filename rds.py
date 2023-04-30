#!/usr/bin/env python
import requests
import json
from json import encoder
import sys
import six
import os
import ec2
import locale
import re
from lxml import etree
from six.moves.urllib import request as urllib2


locale.setlocale(locale.LC_ALL, "en_US.UTF-8")


def add_pretty_names(instances):
    family_names = {
        "t2": "T2 General Purpose",
        "r3": "R3 Memory Optimized",
        "r4": "R4 Memory Optimized",
        "c3": "C3 High-CPU",
        "c4": "C4 High-CPU",
        "m3": "M3 General Purpose",
        "i3": "I3 High I/O",
        "cg1": "Cluster GPU",
        "cc2": "Cluster Compute",
        "cr1": "High Memory Cluster",
        "hs1": "High Storage",
        "c1": "C1 High-CPU",
        "hi1": "HI1. High I/O",
        "m2": "M2 High Memory",
        "m1": "M1 General Purpose",
        "m4": "M4 General Purpose",
    }
    for k in instances:
        i = instances[k]
        # instance type format looks like "db.r4.large"; dropping the "db" prefix
        pieces = i["instance_type"].split(".")
        family = pieces[1]
        short = pieces[2]
        prefix = family_names.get(family, family.upper())
        extra = None
        if short.startswith("8x"):
            extra = "Eight"
        elif short.startswith("4x"):
            extra = "Quadruple"
        elif short.startswith("2x"):
            extra = "Double"
        elif short.startswith("10x"):
            extra = "Deca"
        elif short.startswith("x"):
            extra = ""
        bits = [prefix]
        if extra is not None:
            bits.extend([extra, "Extra"])
            short = "Large"

        bits.append(short.capitalize())

        i["pretty_name"] = " ".join([b for b in bits if b])


def sanitize_instance_type(instance_type):
    """Typos and other bad data are common in the instance type colums for some reason"""
    # Remove random whitespace
    instance_type = re.sub(r"\s+", "", instance_type, flags=re.UNICODE)

    # Correct typos
    typo_corrections = {
        "x1.16large": "x1.16xlarge",  # https://github.com/powdahound/ec2instances.info/issues/199
        "i3.4xlxarge": "i3.4xlarge",  # https://github.com/powdahound/ec2instances.info/issues/227
        "i3.16large": "i3.16xlarge",  # https://github.com/powdahound/ec2instances.info/issues/227
        "p4d.2xlarge": "p4d.24xlarge",  # as of 2020-11-15
    }
    return typo_corrections.get(instance_type, instance_type)


def totext(elt):
    s = etree.tostring(elt, method="text", encoding="unicode").strip()
    return re.sub(r"\*\d$", "", s)


def add_ebs_info(instances):
    """
    Six tables on this page:

    5 of them: EBS optimized by default and baseline:
    Baseline performance metrics for instances with asterisk (unsupported for now, see comment below)
        Instance type | Maximum bandwidth (Mib/s) | Maximum throughput (MiB/s, 128 KiB I/O) | Maximum IOPS (16 KiB I/O)
        Instance type | Baseline bandwidth (Mib/s) | Baseline throughput (MiB/s, 128 KiB I/O) | Baseline IOPS (16 KiB I/O)

    Table 6: Not EBS optimized by default
        Instance type | Maximum bandwidth (Mib/s) | Maximum throughput (MiB/s, 128 KiB I/O) | Maximum IOPS (16 KiB I/O)

    TODO: Support the asterisk on type names in the first table, which means:
        "These instance types can support maximum performance for 30 minutes at least once every 24 hours. For example,
        c5.large instances can deliver 281 MB/s for 30 minutes at least once every 24 hours. If you have a workload
        that requires sustained maximum performance for longer than 30 minutes, select an instance type based on the
        following baseline performance."

    """

    def parse_ebs_combined_table(by_type, table):
        for row in table.xpath("tr"):
            if row.xpath("th"):
                continue
            cols = row.xpath("td")
            instance_type = sanitize_instance_type(totext(cols[0]).replace("*", ""))

            if len(cols) == 4:
                ebs_baseline_bandwidth = locale.atof(totext(cols[1]))
                ebs_baseline_throughput = locale.atof(totext(cols[2]))
                ebs_baseline_iops = locale.atof(totext(cols[3]))
                ebs_max_bandwidth = locale.atof(totext(cols[1]))
                ebs_throughput = locale.atof(totext(cols[2]))
                ebs_iops = locale.atof(totext(cols[3]))
            elif len(cols) == 7:
                ebs_baseline_bandwidth = locale.atof(totext(cols[1]))
                ebs_max_bandwidth = locale.atof(totext(cols[2]))
                ebs_baseline_throughput = locale.atof(totext(cols[3]))
                ebs_throughput = locale.atof(totext(cols[4]))
                ebs_baseline_iops = locale.atof(totext(cols[5]))
                ebs_iops = locale.atof(totext(cols[6]))

            instance_type = "db." + instance_type
            if instance_type in by_type:
                by_type[instance_type]["ebs_optimized"] = True
                by_type[instance_type]["ebs_optimized_by_default"] = True
                by_type[instance_type][
                    "ebs_baseline_throughput"
                ] = ebs_baseline_throughput
                by_type[instance_type]["ebs_baseline_iops"] = ebs_baseline_iops
                by_type[instance_type][
                    "ebs_baseline_bandwidth"
                ] = ebs_baseline_bandwidth
                by_type[instance_type]["ebs_throughput"] = ebs_throughput
                by_type[instance_type]["ebs_iops"] = ebs_iops
                by_type[instance_type]["ebs_max_bandwidth"] = ebs_max_bandwidth

    def parse_ebs_nondefault_table(by_type, table):
        for row in table.xpath("tr"):
            if row.xpath("th"):
                continue
            cols = row.xpath("td")
            instance_type = sanitize_instance_type(totext(cols[0]).replace("*", ""))
            ebs_max_bandwidth = locale.atof(totext(cols[1]))
            ebs_throughput = locale.atof(totext(cols[2]))
            ebs_iops = locale.atof(totext(cols[3]))

            instance_type = "db." + instance_type
            if instance_type not in by_type:
                print(f"ERROR: Ignoring EBS info for unknown instance {instance_type}")
            else:
                if ebs_max_bandwidth:
                    by_type[instance_type]["ebs_optimized"] = True
                by_type[instance_type]["ebs_optimized_by_default"] = False
                by_type[instance_type]["ebs_throughput"] = ebs_throughput
                by_type[instance_type]["ebs_iops"] = ebs_iops
                by_type[instance_type]["ebs_max_bandwidth"] = ebs_max_bandwidth

    by_type = {k: v for k, v in instances.items()}
    # Canonical URL for this info is https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.html
    # ebs_url = "https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.partial.html"
    ebs_url = "https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.html"
    tree = etree.parse(urllib2.urlopen(ebs_url), etree.HTMLParser())
    tables = tree.xpath('//div[@class="table-contents"]//table')
    for t in [0, 1, 2, 3, 4]:
        parse_ebs_combined_table(by_type, tables[t])

    parse_ebs_nondefault_table(by_type, tables[5])


def scrape(output_file, input_file=None):
    # if an argument is given, use that as the path for the json file
    if input_file:
        with open(input_file) as json_data:
            data = json.load(json_data)
    else:
        price_index = "https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonRDS/current/index.json"
        index = requests.get(price_index)
        data = index.json()

    rds_instances = {}
    instances = {}

    # region mapping, someone thought it was handy not to include the region id's :(
    regions = ec2.get_region_descriptions()

    # loop through products, and only fetch available instances for now
    for sku, product in six.iteritems(data["products"]):
        if product.get("productFamily", None) == "Database Instance":
            attributes = product["attributes"]

            # skip multi-az
            if attributes["deploymentOption"] != "Single-AZ":
                continue

            # map the region
            location = ec2.canonicalize_location(attributes["location"])
            instance_type = attributes["instanceType"]
            try:
                region = regions[location]
            except KeyError as e:
                if location == "Any":
                    region = "us-east-1"
                else:
                    print(
                        f"WARNING: No region data for location={location}. Ignoring instance with sku={sku}, type={instance_type}"
                    )
                    continue

            # set the attributes in line with the ec2 index
            attributes["region"] = region
            attributes["memory"] = attributes["memory"].split(" ")[0]
            attributes["network_performance"] = attributes.get(
                "networkPerformance", None
            )
            attributes["family"] = attributes["instanceFamily"]
            attributes["instance_type"] = instance_type
            attributes["database_engine"] = attributes["databaseEngine"]
            attributes["arch"] = attributes.get("processorArchitecture", None)
            attributes["pricing"] = {}
            attributes["pricing"][region] = {}

            if attributes.get("engineCode", None) == None:
                print(f"No Engine Code found. Ignoring instance with sku={sku}")
                continue

            if attributes["engineCode"] not in ["210", "220"]:
                rds_instances[sku] = attributes

                if instance_type not in instances.keys():
                    # delete some attributes that are inconsistent among skus
                    new_attributes = (
                        attributes.copy()
                    )  # make copy so we can keep these attributes with the sku
                    new_attributes.pop("databaseEdition", None)
                    new_attributes.pop("databaseEngine", None)
                    new_attributes.pop("database_engine", None)
                    new_attributes.pop("deploymentOption", None)
                    new_attributes.pop("engineCode", None)
                    new_attributes.pop("licenseModel", None)
                    new_attributes.pop("location", None)
                    new_attributes.pop("locationType", None)
                    new_attributes.pop("operation", None)
                    new_attributes.pop("region", None)
                    new_attributes.pop("usagetype", None)
                    new_attributes["pricing"] = attributes["pricing"]

                    instances[instance_type] = new_attributes

    # Parse ondemand pricing
    for sku, offers in six.iteritems(data["terms"]["OnDemand"]):
        for code, offer in six.iteritems(offers):
            for key, dimension in six.iteritems(offer["priceDimensions"]):
                # skip these for now
                if any(
                    descr in dimension["description"].lower()
                    for descr in [
                        "transfer",
                        "global",
                        "storage",
                        "iops",
                        "requests",
                        "multi-az",
                    ]
                ):
                    continue

                instance = rds_instances.get(sku)
                if not instance:
                    # print(f"WARNING: Received on demand pricing info for unknown sku={sku}")
                    continue

                if (
                    instance["region"]
                    not in instances[instance["instance_type"]]["pricing"]
                ):
                    instances[instance["instance_type"]]["pricing"][
                        instance["region"]
                    ] = {}

                instances[instance["instance_type"]]["pricing"][instance["region"]][
                    instance["engineCode"]
                ] = {"ondemand": float(dimension["pricePerUnit"]["USD"])}

                # keep this for backwards compatibility, even though it's wrong
                # (database_engine is not unique, so multiple offerings overlap)
                instances[instance["instance_type"]]["pricing"][instance["region"]][
                    instance["database_engine"]
                ] = {"ondemand": float(dimension["pricePerUnit"]["USD"])}

    reserved_mapping = {
        "3yr Partial Upfront": "yrTerm3.partialUpfront",
        "1yr Partial Upfront": "yrTerm1.partialUpfront",
        "3yr All Upfront": "yrTerm3.allUpfront",
        "1yr All Upfront": "yrTerm1.allUpfront",
        "1yr No Upfront": "yrTerm1.noUpfront",
        "3yr No Upfront": "yrTerm3.noUpfront",
    }

    # Parse reserved pricing
    for sku, offers in six.iteritems(data["terms"]["Reserved"]):
        for code, offer in six.iteritems(offers):
            for key, dimension in six.iteritems(offer["priceDimensions"]):
                instance = rds_instances.get(sku)
                if not instance:
                    # print(f"WARNING: Received reserved pricing info for unknown sku={sku}")
                    continue

                # skip multi-az
                if instance["deploymentOption"] != "Single-AZ":
                    continue

                region = instance["region"]

                # create a regional hash
                if region not in instance["pricing"]:
                    instance["pricing"][region] = {}

                # create a database_engine hash
                if instance["database_engine"] not in instance["pricing"][region]:
                    instance["pricing"][region][instance["database_engine"]] = {}
                if instance["engineCode"] not in instance["pricing"][region]:
                    instance["pricing"][region][instance["engineCode"]] = {}

                # create a reserved hash
                if (
                    "reserved"
                    not in instances[instance["instance_type"]]["pricing"][
                        instance["region"]
                    ][instance["database_engine"]]
                ):
                    instances[instance["instance_type"]]["pricing"][instance["region"]][
                        instance["database_engine"]
                    ]["reserved"] = {}
                if (
                    "reserved"
                    not in instances[instance["instance_type"]]["pricing"][
                        instance["region"]
                    ][instance["engineCode"]]
                ):
                    instances[instance["instance_type"]]["pricing"][instance["region"]][
                        instance["engineCode"]
                    ]["reserved"] = {}

                reserved_type = "%s %s" % (
                    offer["termAttributes"]["LeaseContractLength"],
                    offer["termAttributes"]["PurchaseOption"],
                )

                instances[instance["instance_type"]]["pricing"][instance["region"]][
                    instance["engineCode"]
                ]["reserved"][
                    "%s-%s"
                    % (reserved_mapping[reserved_type], dimension["unit"].lower())
                ] = float(
                    dimension["pricePerUnit"]["USD"]
                )
                instances[instance["instance_type"]]["pricing"][instance["region"]][
                    instance["database_engine"]
                ]["reserved"][
                    "%s-%s"
                    % (reserved_mapping[reserved_type], dimension["unit"].lower())
                ] = float(
                    dimension["pricePerUnit"]["USD"]
                )

    # Calculate all reserved effective pricings (upfront hourly + hourly price)
    for instance_type, instance in six.iteritems(instances):
        for region, pricing in six.iteritems(instance["pricing"]):
            for engine, prices in six.iteritems(pricing):
                if "reserved" not in prices:
                    continue
                try:
                    # no multi-az here
                    reserved_prices = {}

                    if "yrTerm3.partialUpfront-quantity" in prices["reserved"]:
                        reserved_prices["yrTerm3Standard.partialUpfront"] = (
                            prices["reserved"]["yrTerm3.partialUpfront-quantity"]
                            / (365 * 3)
                            / 24
                        ) + prices["reserved"]["yrTerm3.partialUpfront-hrs"]

                    if "yrTerm1.partialUpfront-quantity" in prices["reserved"]:
                        reserved_prices["yrTerm1Standard.partialUpfront"] = (
                            prices["reserved"]["yrTerm1.partialUpfront-quantity"]
                            / 365
                            / 24
                        ) + prices["reserved"]["yrTerm1.partialUpfront-hrs"]

                    if "yrTerm3.allUpfront-quantity" in prices["reserved"]:
                        reserved_prices["yrTerm3Standard.allUpfront"] = (
                            prices["reserved"]["yrTerm3.allUpfront-quantity"]
                            / (365 * 3)
                            / 24
                        ) + prices["reserved"]["yrTerm3.allUpfront-hrs"]

                    if "yrTerm1.noUpfront-hrs" in prices["reserved"]:
                        reserved_prices["yrTerm1Standard.noUpfront"] = prices[
                            "reserved"
                        ]["yrTerm1.noUpfront-hrs"]

                    if "yrTerm3.noUpfront-hrs" in prices["reserved"]:
                        reserved_prices["yrTerm3Standard.noUpfront"] = prices[
                            "reserved"
                        ]["yrTerm3.noUpfront-hrs"]

                    instances[instance_type]["pricing"][region][engine][
                        "reserved"
                    ] = reserved_prices
                except Exception as e:
                    print(
                        "ERROR: Trouble generating RDS reserved price for {}: {!r}".format(
                            instance_type, e
                        )
                    )

    add_pretty_names(instances)
    for i, v in instances.items():
        v["ebs_baseline_bandwidth"] = 0
        v["ebs_baseline_throughput"] = 0
        v["ebs_baseline_iops"] = 0
        v["ebs_max_bandwidth"] = 0
        v["ebs_throughput"] = 0
        v["ebs_iops"] = 0
    add_ebs_info(instances)

    # write output to file
    encoder.FLOAT_REPR = lambda o: format(o, ".5f")
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, "w+") as outfile:
        json.dump(list(instances.values()), outfile, indent=1)


if __name__ == "__main__":
    input_file = None
    if len(sys.argv) > 1:
        input_file = sys.argv[1]

    output_file = "./www/rds/instances.json"
    scrape(output_file, input_file)
