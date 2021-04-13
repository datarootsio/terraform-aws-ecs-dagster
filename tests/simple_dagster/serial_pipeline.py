import csv
import os

from dagster import pipeline, solid

@solid
def load_cereals(_):
    dataset_path = os.path.join(os.path.dirname(__file__), "cereal.csv")
    with open(dataset_path, "r") as fd:
        cereals = [row for row in csv.DictReader(fd)]
    return cereals


@solid
def sort_by_calories(_, cereals):
    sorted_cereals = list(
        sorted(cereals, key=lambda cereal: cereal["calories"])
    )
    most_calories = sorted_cereals[-1]["name"]
    return most_calories


@solid
def sort_by_protein(_, cereals):
    sorted_cereals = list(
        sorted(cereals, key=lambda cereal: cereal["protein"])
    )
    most_protein = sorted_cereals[-1]["name"]
    return most_protein


@solid
def display_results(context, most_calories, most_protein):
    context.log.info(f"Most caloric cereal: {most_calories}")
    context.log.info(f"Most protein-rich cereal: {most_protein}")


@pipeline
def complex_pipeline():
    cereals = load_cereals()
    display_results(
        most_calories=sort_by_calories(cereals),
        most_protein=sort_by_protein(cereals),
    )